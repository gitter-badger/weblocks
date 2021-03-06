=======
 Hints
=======

Basic SBCL setup
================

I recommend the following SBCL initialization file (on UNIX systems it is ``~/.sbclrc``:


.. code:: common-lisp
          
   ; stale FASLs
   (defmethod asdf:perform :around ((o asdf:load-op) (c asdf:cl-source-file))
       (handler-case (call-next-method o c)
         (#+sbcl sb-ext:invalid-fasl
          #-(or sbcl allegro lispworks cmu) error ()
          (asdf:perform (make-instance 'asdf:compile-op) c)
          (call-next-method))))


Using:

* aclrepl (see also http://www.sbcl.org/manual/sb_002daclrepl.html);
* rlwrap (http://freshmeat.net/projects/rlwrap/);
* clbuild.


Deployment
==========

* detachtty
* screen
* tmux
* remote swank


Store comparison
================

Different stores have different merits. Here's a short comparison.


cl-prevalence
-------------

This library embodies the prevalence database strategy:
Everything is kept in main memory; all writes are logged
to disk, and the in-memory database is restored with the
aid of the log at initialization time.

Advantages
~~~~~~~~~~

* This means excellent speed and seamless integration with CL as query
  language.


Disadvantages
~~~~~~~~~~~~~

* No transaction support for objects in memory.

* Database size limited by size of virtual memory.

* No load balancing capabilities (but you can run the
  database on a separate machine)

Bottom line
~~~~~~~~~~~

Prevalence is a great library to start with because you
can do carefree prototyping and also run production sites.

w_strong(Important note:) The original version of cl-prevalence has
some bugs that prevent it from working reliably when used with Weblocks.

It is recommended to use the fork at
http://bitbucket.org/skypher/cl-prevalence/ where this problem has been
remedied.


Elephant
--------

Elephant is based on a key-value database model (like SQL servers)
It offers convenient CLOS integration and decent speed.

Advantages
~~~~~~~~~~

* Transactions affect in-memory objects.

* Excellent support for schema updates: Elephant manages
  most issues on its own even across process boundaries.
  Special cases (slot migration/deletion) can be specified
  by the user by hooking into the MOP.

* Queries are formulated completely in CL.

Negatives
~~~~~~~~~

* Less speed than cl-prevalence especially with a high
  number of slot accesses.

* Watch out when handling primitive types like arrays
  and conses, Elephant doesn't have its hooks in there.
  
* BDB backend: load balancing not easily realized.
  
* PostgreSQL backend: incomplete support for sorting
  values containing NIL.

Bottom line
~~~~~~~~~~~

Not as easy to set up as cl-prevalence, but a great library
to work with.


CLSQL
-----

The CLSQL store relies on the popular SQL ecosystem. This means
proven client-server management systems like PostgreSQL, hosts
of excellent tools and great interoperability.

On the negative side SQL has an impedance mismatch when matched
against object-oriented data structures.

You cannot use CL as a query language either, CLSQL only provides
a Lispy layer over SQL.


Weblocks compared to other frameworks
=====================================

At a glance
-----------

.. list-table:: Weblocks compared with other frameworks
   :header-rows: 1

   * -
     - Weblocks
     - Seaside
     - PLT Webserver
     - RubyOnRails
     - Django
   * - Language
     - Common Lisp
     - Smalltalk
     - Scheme
     - Ruby
     - Python
   * - Supports REST
     - Yes
     -
     - Yes
     - Yes
     - Yes
   * - Suports multi-tier dispatch
     - Yes
     -
     -
     -
     -
   * - AJAX support built-in
     - Yes
     -
     -
     - No
     - No
   * - Degrades gracefully without AJAX
     - Yes
     - (N/A)
     - (N/A)
     - No
     - No
   * - Scaffolding/DRY
     - Dynamic
     -
     - No
     - Static
     -
   * - Support for non-SQL databases
     - Yes
     -
     - Yes
     - No
     -
   * - Interactive debugging
     - Yes
     - Yes
     - Yes
     - No
     - No
   * - Bundling/compression built-in
     - Yes
     -
     -
     - No
     - No
   * - Community
     - Tiny
     - Small
     - Small
     - Medium
     - Medium
   * - Community support
     - Yes
     -
     -
     - Yes
     - Yes
   * - Commercial support
     - Yes
     -
     -
     - Yes
     - Yes
   * - Licence
     - LLGPL
     -
     -
     -
     - 


In-depth comparison
-------------------

Weblocks

Django:		read basics at djangobook.com
	  	Django works at a level similar to hunchentoot. A series of urls is mapped to functions. Templates can be used to fill in html.
		Uses mvc.

Python:		Twisted?
		Google App Engine?

Rails:    	Uses mvc. Ruby has some nice language features. Framework is backwards, and forces you to repeat yourself many times. A guiding
		principle is to not repeat yourself (colloquially DRY) and in combination with a poor DSL it can be quite gibberishy.
                Strongly tied to SQL as data store.

Ruby:		Other?

Perl:		Mason?

PHP:		Cake?

Seaside
