
(in-package :weblocks)

(export '(*submit-control-name* *cancel-control-name* with-html-form
	  render-link render-button render-checkbox render-dropdown
	  *dropdown-welcome-message* render-radio-buttons
	  render-close-button render-password render-textarea))

(defparameter *submit-control-name* "submit"
  "The name of the control responsible for form submission.")

(defparameter *cancel-control-name* "cancel"
  "The name of the control responsible for cancellation of form
  submission.")

(defmacro with-html-form ((method-type action &key id class) &body body)
  "Transforms to cl-who (:form) with standard form code (AJAX support, actions, etc.)"
  (let ((action-code (gensym)))
    `(let ((,action-code (function-or-action->action ,action)))
       (with-html
	 (:form :id ,id :class ,class :action (request-uri-path) :method (attributize-name ,method-type)
		:onsubmit (format nil "initiateFormAction(\"~A\", $(this), \"~A\"); return false;"
				  (url-encode (or ,action-code ""))
				  (session-name-string-pair))
		(with-extra-tags
		  (htm (:fieldset
			,@body
			(:input :name *action-string* :type "hidden" :value ,action-code)))))))))

(defun render-link (action name &key (ajaxp t) id class)
  "Renders an action into an href link. If 'ajaxp' is true (the
default), the link will be rendered in such a way that the action will
be invoked via AJAX, or will fall back to regular request if
JavaScript is not available. When the user clicks on the link, the
action will be called on the server.

'action' - may be a function (in which case 'render-link' will
automatically call 'make-action'), or a result of a call
to 'make-action'.
'name' - A string that will be presented to the user in the
link.
'ajaxp' - whether link is submitted via AJAX if JS is available (true
by default).
'id' - An id passed into HTML.
'class' - A class placed into HTML."
  (let* ((action-code (function-or-action->action action))
	 (url (make-action-url action-code)))
    (with-html
      (:a :id id :class class
	  :href url :onclick (when ajaxp
			       (format nil "initiateAction(\"~A\", \"~A\"); return false;"
				       action-code (session-name-string-pair)))
	  (str name)))))

(defun render-button (name  &key (value (humanize-name name)) id (class "submit"))
  "Renders a button in a form.

'name' - name of the html control. The name is attributized before
being rendered.
'value' - a value on html control. Humanized name is default.
'id' - id of the html control. Default is nil.
'class' - a class used for styling. By default, \"submit\"."
  (with-html
    (:input :name (attributize-name name) :type "submit" :id id :class class
	    :value value :onclick "disableIrrelevantButtons(this);")))

(defun render-checkbox (name checkedp &key id (class "checkbox"))
  "Renders a checkbox in a form.

'name' - name of the html control. The name is attributized before
being rendered.
'checkedp' - if true, renders the box checked.
'id' - id of the html control. Default is nil.
'class' - a class used for styling. By default, \"submit\"."
  (with-html
    (if checkedp
	(htm (:input :name (attributize-name name) :type "checkbox" :id id :class class
		     :value "t" :checked "checked"))
	(htm (:input :name (attributize-name name) :type "checkbox" :id id :class class
		     :value "t")))))

(defparameter *dropdown-welcome-message* "[Select ~A]"
  "A welcome message used by dropdowns as the first entry.")

(defun render-dropdown (name selections &key id class selected-value welcome-name)
  "Renders a dropdown HTML element (select).

'name' - the name of html control. The name is attributized before
being rendered.

'selections' - a list of strings to render as selections. Each element
may be a string or a cons cell. If it is a cons cell, the car of each
cell will be used as the text for each option and the cdr will be used
for the value.

'id' - an id of the element.

'class' - css class of the element.

'selected-value' - a list of strings. Each option will be tested
against this list and if an option is a member it will be marked as
selected. A single string can also be provided.

'welcome-name' - a string used to specify dropdown welcome option (see
*dropdown-welcome-message*). If nil, no welcome message is used. If
'welcome-name' is a cons cell, car will be treated as the welcome name
and cdr will be returned as value in case it's selected."
  (when welcome-name
    (setf welcome-name (car (list->assoc (list welcome-name)
					 :map (constantly "")))))
  (with-html
    (:select :id id
	     :class class
	     :name (attributize-name name)
	     (mapc (lambda (i)
		     (if (member (format nil "~A" (or (cdr i) (car i)))
				 (ensure-list selected-value)
				 :test #'equalp :key (curry #'format nil "~A"))
			 (htm (:option :value (cdr i) :selected "selected" (str (car i))))
			 (htm (:option :value (cdr i) (str (car i))))))
		   (list->assoc (append (when welcome-name
					  (list
					   (cons (format nil *dropdown-welcome-message* (car welcome-name))
						 (cdr welcome-name))))
					selections)
				:map (constantly nil))))))

(defun render-radio-buttons (name selections &key id (class "radio") selected-value)
  "Renders a group of radio buttons.

'name' - name of radio buttons.
'selections' - a list of selections. May be an association list, in
which case its car is used to dispaly selection text, and cdr is used
for the value.
'id' - id of a label that holds the radio buttons.
'class' - class of the label and of radio buttons.
'selected-value' - selected radio button value."
  (loop for i in (list->assoc selections)
        for j from 1
        with count = (length selections)
        for label-class = (cond
			    ((eq j 1) (concatenate 'string class " first"))
			    ((eq j count) (concatenate 'string class " last"))
			    (t class))
        do (progn
	     (when (null selected-value)
	       (setf selected-value (cdr i)))
	     (with-html
	       (:label :id id :class label-class
		       (if (equalp (cdr i) selected-value)
			   (htm (:input :name (attributize-name name) :type "radio" :class "radio"
					:value (cdr i) :checked "checked"))
			   (htm (:input :name (attributize-name name) :type "radio" :class "radio"
					:value (cdr i))))
		       (:span (str (format nil "~A&nbsp;" (car i)))))))))

(defun render-close-button (close-action &optional (button-string "(Close)"))
  "Renders a close button. If the user clicks on the close button,
'close-action' is called back. If 'button-string' is provided, it used
used instead of the default 'Close'."
  (with-html
    (:span :class "close-button"
	   (render-link close-action (humanize-name button-string)))))

;;; render password implementation
(defun render-password (name value &key id (class "password") maxlength)
    "Renders a password in a form.
'name' - name of the html control. The name is attributized before being rendered.
'value' - a value on html control.
'id' - id of the html control. Default is nil.
 maxlength - maximum lentgh of the field
'class' - a class used for styling. By default, \"password\"."
  (with-html
    (:input :type "password" :name (attributize-name name) :id id
	    :value value :maxlength maxlength :class class)))


(defun render-textarea (name value rows cols &key id class)
  "Renders a textarea in a form.
'name' - name of the html control. The name is attributized before being rendered.
'value' - a value on html control. Humanized name is default.
'id' - id of the html control. Default is nil.
'maxlength' - maximum lentgh of the field  
'rows' - number of rows in textarea
'cols' - number of columns in textarea
'class' - a class used for styling. By default, \"textarea\"."
  (with-html
      (:textarea :name (attributize-name name) :id id
		 :rows rows :cols cols :class class
		 (str (or value "")))))

