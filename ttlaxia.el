;;; ttlaxia.el --- make a blog using only org-mode and atom.el

;; Copyright 2012, Evans Winner, All rights reserved.

;;; Other people's code:

;; There is an org-atom.el out there, but I couldn't get it to work
;; for any but trivial test cases, and it doesn't seem very flexible.
;; So instead we use Frédéric Perrin's atom.el.  See
;; http://tar-jx.bz/code/atom.html
(require 'atom)
(require 'xml-xhtml-entities)
(setq xml-entity-alist (cons '("#x2013" . "#x2013") xml-entity-alist))
(setq xml-entity-alist (cons '("#x2014" . "#x2014") xml-entity-alist))


(require 'org)
(require 'ox)
;;; For fontlock for output for at least one post:
(require 'css-mode)
;(require 'nxhtml)
(load "~/src/nxhtml/autostart.el")
(setq org-src-fontify-natively t)
(require 'ctrl-lang)			;my own library for AS/400 Control Language files

;; Inspired by function from the elisp cookbook
;; http://emacswiki.org/emacs/ElispCookbook#toc45
;; (defun file-to-string (file)
;;   "Read the contents of a file and return as a string."
;;   (with-temp-buffer
;;     (insert-file file)
;;     (buffer-string)))

;; For debugging -- to inspect the results of rendering.  Taken from
;; https://sinewalker.wordpress.com/2008/06/26/pretty-printing-xml-with-emacs-nxml-mode/
(defun ttlaxia-pretty-print-xml-region (begin end)
  "Pretty format XML markup in region.
You need to have nxml-mode
http://www.emacswiki.org/cgi-bin/wiki/NxmlMode installed to do
this.  The function inserts linebreaks to separate tags that have
nothing but whitespace between them.  It then indents the markup
by using nxml's indentation rules."
  (interactive "r")
  (save-excursion
      (nxml-mode)
      (goto-char begin)
      (while (search-forward-regexp "\>[ \\t]*\<" nil t)
	(backward-char) (insert "\n"))
      (indent-region begin end))
    (message "Ah, much better!"))


;;; Variables

(defvar ttlaxia-base-url "http://ttlaxia.net/")
(defvar ttlaxia-blog-title "Ttlåxia-Verlag")
(defvar ttlaxia-blog-subtitle (concat "The official broadcasting instrument of "
				    "<a id=\"author-link\" href=\"ehwinner.html\">"
				    "E.&nbsp;Hawthorne&nbsp;Winner</a>┫"))
(defvar ttlaxia-src-dir "~/cloud/ttlaxia/ttlaxia/") ;use trailing slash
(defvar ttlaxia-target-dir "~/cloud/ttlaxia/ttlaxia/") ;use trailing slash
(defvar ttlaxia-homepage-name "index.html")
(defvar ttlaxia-feed-name "index.atom")
(defvar ttlaxia-archive-page-name "archive.html")
(defvar ttlaxia-homepage-length 1)
(defvar ttlaxia-author "E. Hawthorne Winner"	;will default to `user-full-name' if not set.
  "The default author name.  This can be overridden with the
#+AUTHOR in-buffer setting for a given post.")
(defvar ttlaxia-author-email "ego111@gmail.com" ;will default to `user-mail-address' if not set.
  "The email address of the author if you want it posted.

Otherwise nil.  Can be overridden with the #+EMAIL in-buffer
setting for a given post.")

(defvar ttlaxia-author-web "ehwinner.html"
  "Non-absolute url to an about the author page.

This is not integrated well, yet, to allow multiple authors.")

(defconst ttlaxia-feed-length 150
  "The maximum number of items to include in the atom feed.

The wisdom seems to be that 150 is the largest number on which
common feed readers won't choke.")

(defvar ttlaxia-blog nil
  "This is where the needed data will be kept as a list of post structs.

Each sublist will be the data for a single post in the blog.  The
list will get sorted by data for the most important uses, and may
also be scanned for tags entries, as well, if I get around to
implementing that.")

(defvar ttlaxia-homepage-html-header
  (concat
   "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
   "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" "
   "\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n"
   "<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"en\" xml:lang=\"en\">\n"
   "<head>\n"
   "<title>" ttlaxia-blog-title "</title>\n"
   "<meta http-equiv=\"Content-type\" content=\"text/html;charset=UTF-8\" />"
   "<link href=\"http://fonts.googleapis.com/css?family=Bitter|Inconsolata\" rel=\"stylesheet\" type=\"text/css\" />\n"
;   "rel=\"stylesheet\" type=\"text/css\" />\n"
   "<link rel=\"shortcut icon\" type=\"image/x-icon\" href=\"/favicon.ico\" />"
   "<link rel=\"stylesheet\" type=\"text/css\" href=\"ttlaxia.css\" />\n"
   "<link rel=\"alternate\" type=\"application/atom+xml\" href=\"/index.atom\" title=\"Ttlåxia-Verlag\" />"
   "</head>\n<body>\n"))

(defvar ttlaxia-feed-button
  "<a href=\"index.atom\"><img src=\"feed.gif\" width=\"12\" height=\"12\" alt=\"Atom feed\" />")

(defvar ttlaxia-addtoany-script
  "<!-- Lockerz Share BEGIN -->
<a class=\"a2a_dd\" href=\"http://www.addtoany.com/share_save?linkurl=http%3A%2F%2Fttlaxia.net&amp;linkname=Ttl%C3%A5xia-Verlag\"><img src=\"http://static.addtoany.com/buttons/share_save_171_16.png\" width=\"171\" height=\"16\" alt=\"Share\"/></a>
<script type=\"text/javascript\">
var a2a_config = a2a_config || {};
a2a_config.linkname = \"Ttlåxia-Verlag\";
a2a_config.linkurl = \"http://ttlaxia.net\";
a2a_config.onclick = 1;
a2a_config.num_services = 22;
a2a_config.prioritize = [\"facebook\", \"twitter\", \"printfriendly\", \"email\", \"google_gmail\", \"google_plus\", \"google_bookmarks\", \"digg\", \"citeulike\", \"delicious\", \"linkedin\", \"read_it_later\", \"slashdot\", \"reddit\"];
</script>
<script type=\"text/javascript\" src=\"http://static.addtoany.com/menu/page.js\"></script>
<!-- Lockerz Share END -->")

(defvar ttlaxia-twitter-feed-url
  "https://api.twitter.com/1/statuses/user_timeline.rss?screen_name=thorne")

(defvar ttlaxia-homepage-html-footer
  "</body>\n</html>\n")

(defvar ttlaxia-adsense-blob
  "<script type=\"text/javascript\"><!--
google_ad_client = \"ca-pub-3268989123621768\";
/* 125x125, created 7/6/09 */
google_ad_slot = \"8828829407\";
google_ad_width = 125;
google_ad_height = 125;
//-->
</script>
<script type=\"text/javascript\"
src=\"http://pagead2.googlesyndication.com/pagead/show_ads.js\">
</script>")

(defvar ttlaxia-disqus-blob "<div id=\"disqus_thread\"></div>
	<script type=\"text/javascript\">
	    /* * * CONFIGURATION VARIABLES: EDIT BEFORE PASTING INTO YOUR WEBPAGE * * */
	    var disqus_shortname = 'ttlaxia'; // required: replace example with your forum shortname

	    /* * * DON'T EDIT BELOW THIS LINE * * */
	    (function() {
		var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
		dsq.src = 'http://' + disqus_shortname + '.disqus.com/embed.js';
		(document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
	    })();
	</script>
	<noscript>Please enable JavaScript to view the <a href=\"http://disqus.com/?ref_noscript\">comments powered by Disqus.</a></noscript>
	<a href=\"http://disqus.com\" class=\"dsq-brlink\">comments powered by <span class=\"logo-disqus\">Disqus</span></a>")

(defstruct post				;use "in-buffer"settings, or see globals variables above
  title					;the FIRST 
  date					;#+DATE:<2012-09-17 Mon>
  (author ttlaxia-author)		;#+AUTHOR: ...
  (email ttlaxia-author-email)		;#+EMAIL: ...
  description                           ;#+DESCRIPTION: ... don't actually use this yet
  tags					;#+KEYWORDS ...
  source				;the source file
  rendered				;the local location of the rendered file
  url)					;the permalink url


;;; Pdf versions of posts and images and other "static" files.  Just
;;; use org-publish for this:

(setq org-publish-project-alist
      '(("pdf"
	 :base-directory "~/cloud/ttlaxia/ttlaxia/"
	 :base-extension "org"
	 :publishing-directory "~/cloud/ttlaxia/ttlaxia/"
	 :recursive t
	 :section-numbers nil
	 :table-of-contents t
	 :publishing-function org-latex-publish-to-pdf
	 :headline-levels 4
	 :auto-preamble t)
	("static"
	 :base-directory "~/cloud/ttlaxia/ttlaxia/"
	 :base-extension "css\\|js\\|png\\|jpg\\|gif\\|pdf\\|org\\|ico\\|vcf\\|el"
	 :publishing-directory "~/cloud/ttlaxia/ttlaxia/"
	 :recursive t
	 :publishing-function org-publish-attachment)
	("ttlaxia" :components ("pdf" "static"))))

;;(setq org-export-with-toc t)
(setq org-startup-with-inline-images t)
;(setq org-export-html-style "<link rel=\"stylesheet\" type=\"text/css\" href=\"ttlaxia.css\" />")
(setq org-coding-system 'utf-8)
(setq org-html-style-include-default nil)
(setq org-html-inline-images 1)
(setq org-html-link-home ttlaxia-homepage-name)
(setq org-confirm-babel-evaluate nil)
;(setq org-export-babel-evaluate t)
;; (setq org-export-with-section-numbers nil)

;; I am getting mumamo and/or nxhtml errors and I think this will fix
;; it.  
(defun ttlaxia-write-file (file &optional confirm)
  (let ((auto-mode-alist nil))
    (write-file file nil)))

;;; Create database from which we can construct the index, the
;;; homepages, the archive(s), and  the atom feed.

;; This will be used to truncate the list in several places.
(defun first-n (list n)
  "Return just the first N-length part of LIST."
  (if (< 0 (- (length list) n))
      list)
  (butlast list (- (length list) n)))


;;; The post database and data structure

(defun ttlaxia-list-src-files ()
  "Get a list of all the source files in the source directory."
  (directory-files (expand-file-name ttlaxia-src-dir) t ".org$" t))

;; This is a hack that is only intended to work for this single use.
;; There is probably a more elegant way to do it.  I HOPE there is a
;; more elegant way to do it.
;; (defun ttlaxia-get-title ()
;;   (goto-char (point-min))		;not strictly necessary here, I think
;;   (outline-next-visible-heading 1)
;;   (org-get-heading))

(defun ttlaxia-list-keywords (string)
  "Turn a string of the form \"foo,bar,baz\" into a list of the form
\(\"foo\" \"bar\" \"baz\"\)."
  (split-string
   (replace-regexp-in-string " " "" string)
   ","))

(defun ttlaxia-make-post (file)
  (with-temp-buffer
    (insert-file file)
    (org-mode)
    (make-post
     :title (car (plist-get (org-export-get-environment) :title))
     :date (substring (plist-get  (cadar (plist-get (org-export-get-environment) :date)) :raw-value) 1 11)
     :author (or (car (plist-get (org-export-get-environment) :author))
		 ttlaxia-author
		 user-full-name)
     :email (or ttlaxia-author-email
		(plist-get (org-export-get-environment) :email)
		user-mail-address)
     :description (plist-get (org-export-get-environment) :description)
     :tags (if (plist-get (org-export-get-environment) :keywords)
	       (ttlaxia-list-keywords (plist-get (org-export-get-environment) :keywords))
	     nil)
     :source (expand-file-name file)
     :rendered (expand-file-name
		(concat ttlaxia-target-dir
			(file-name-sans-extension
			 (file-name-nondirectory file)) ".html"))
     :url (concat ttlaxia-base-url
		  (file-name-sans-extension
		   (file-name-nondirectory file)) ".html"))))

(defun ttlaxia-compile-db ()
  "Make a list of post structs, one for each post in the src dir."
  (let ((output nil))
    (dolist (file (ttlaxia-list-src-files) output)
      (setq output (cons (ttlaxia-make-post file) output)))))

(defun ttlaxia-post-older-p (this that)
  (org-time>
   (post-date this)
   (post-date that)))

(defun ttlaxia-sort-db (db)
  (sort db 'ttlaxia-post-older-p))

;; Note that the org-mode property that is queried only returns the
;; date of the post, and ignores the time, even if the time is set in
;; the #+DATE in-buffer setting.  Some feed readers don't like to have
;; multiple posts with the same time stamp, so this means that there
;; could be problems if you post more than once per day.  Not sure how
;; to solve this at the moment.
(defun ttlaxia-make-db ()
  "Make a list of post structs, one for each post in the src
dir, and sort the resulting list, most recent post first."
  (ttlaxia-sort-db (ttlaxia-compile-db)))

;; The only lispy thing in sight.  Schemers would be proud... until
;; they learned that Emacs Lisp doesn't optimize tail-calls... I
;; guess.
(defun ttlaxia-find-neighboring-posts (post db)
  "For a given POST which is assumed to be a member of DB, return
a list of two elements: first, the preceeding post or nil if
there isn't one, and second, the following post, or nil if there
isn't one."
  (if (equal post (car db))		;first one, so no predecessor.
      (list nil (cadr db))		;will never happen unless on first call
    (if (null (cdr db))			;last one, so no follower
	(list post nil)
      (if (equal post (cadr db))
	  (list (car db) (caddr db))
	   (ttlaxia-find-neighboring-posts post (cdr db))))))

(defun ttlaxia-find-previous-post (post db)
  (cadr (ttlaxia-find-neighboring-posts post db)))

(defun ttlaxia-find-next-post (post db)
  (car (ttlaxia-find-neighboring-posts post db)))


;;; tags

(defun ttlaxia-list-tags (db)
  "Initialize with tags what will become an alist of tag,
list-of-posts-with-that-tag pairs."
  (setq tags-list nil)
  (setq rtn nil)
  (dolist (post db)
    (dolist (tag (post-tags post))
      (add-to-list 'tags-list (list tag))))
  tags-list)

(defun ttlaxia-find-tagged-posts-in-db (tag db)
  (setq rtn nil)
  (dolist (post db)
    (if (member (car tag) (post-tags post))
	(setq rtn (cons post rtn))))
  (list (car tag) rtn))

(defun ttlaxia-make-tags-db (db)
  "Fill an alist made by `ttlaxia-list-tags'."
  (loop for tag in (ttlaxia-list-tags db) collect
	(ttlaxia-find-tagged-posts-in-db tag db)))

(defun ttlaxia-tags-db-string< (this that)
  (string< (car this) (car that)))

(defun ttlaxia-has-more-tags-p (this that)
  (> (length (cadr this)) (length (cadr that))))

(defun ttlaxia-sort-tag-db (tag-db &optional sort-func)
  (let ((func (or sort-func 'ttlaxia-tags-db-string<)))
    (sort tag-db func)))

(defun ttlaxia-produce-tags-db (post-db &optional sort-func)
  "Given a post database, return a sorted tags
database. SORT-FUNC defaults to sorting by alpha."
  (ttlaxia-sort-tag-db (ttlaxia-make-tags-db post-db)
		       (or sort-func 'ttlaxia-tags-db-string<)))

(defun ttlaxia-tags-index (sorted-tags-db)
  (loop for tag in sorted-tags-db collect
	(car tag)))

(defun ttlaxia-get-tagged-posts (tag tags-db)
  "List all posts in TAGS-DB tagged with TAG."
  (cadr (assoc tag tags-db)))

;; Probably the main interface.
(defun ttlaxia-list-tagged-posts (tag post-db)
  "Given a posts database, list all posts tagged with TAG."
  (ttlaxia-get-tagged-posts tag (ttlaxia-produce-tags-db post-db)))

(defun ttlaxia-make-tag-link (post)
  (concat "<a href=\"" (file-name-nondirectory (post-url post)) "\">"
	  (post-title post) "</a>"))

(defun ttlaxia-do-tags-list (post-db &optional sort-func count)
  "Do the tags list thing.  SORT-FUNC defaults to alphabetical
with `ttlaxia-tags-db-string<'.  Optionally, use only the first
COUNT items in the database."
  (let* ((sorter (or sort-func 'ttlaxia-tags-db-string<))
	 (dab (ttlaxia-produce-tags-db post-db sorter))
	 (dab (if count (first-n dab count) dab)))
    (setq thing "")
    (setq thing
	  (concat
	   (dolist
	       (one-tag (reverse dab) thing)
	     (setq thing
		   (concat "<a href=\"tags.html#"
			   (car one-tag) "\">" (car one-tag)
			   "</a> " thing)))))))

(defun ttlaxia-make-tags-page (db)
  (let ((tags-db (ttlaxia-produce-tags-db db)))
    (with-temp-buffer
      (kill-region (point-min) (point-max)) ;just in case? dumb?
      (goto-char (point-min))
      (insert
       ttlaxia-homepage-html-header
       "<div id=\"tags-page\">\n<center><a href=\"" ttlaxia-homepage-name "\">☝</a></center><br />\n"
       "<h1>Ttlåxia-Verlag: Posts by tag</h1>\n")
      (insert (ttlaxia-do-tags-list db))
      (dolist (tag tags-db)
	(insert "<br /><br />\n<a id=\"tag\" name=\"" (car tag) "\"><em><b>\"" (car tag) "\"</b></em></a><br />\n")
	(dolist (post (reverse (cadr (assoc (car tag) tags-db))))
	  (insert
	   (post-date post)
	   " — <a href=\"" (file-name-nondirectory (post-url  post)) "\"><em><b>\n"
	   (post-title post) "</b></em></a>\n"
	   "<div id=\"tags-tags\"> — Tags: ")
	  (dolist (string (post-tags post))
	    (insert "<a href=\"#" string "\">" string "</a>, "))
	  (insert "</div>\n")))
      (insert "</div>\n")
      (insert ttlaxia-homepage-html-footer)
      (ttlaxia-write-file (concat ttlaxia-target-dir "tags.html") nil))))

;;; The homepage

;; This is used for the permalink generation now too.  This is the
;; basic function that takes an org-mode file and outputs a string
;; containing the HTML result of exporting it with org-mode's
;; function.
(defun ttlaxia-render-one (file)
  (let ((org-export-show-temporary-export-buffer nil))
    (save-excursion
      (let ((buffer (set-buffer (find-file file)))) ;
  	(setq rtn (org-export-as 'html nil nil t nil))
  	(kill-buffer buffer)
  	rtn))))
  ;; (save-excursion
  ;;   (let* ((org-export-show-temporary-export-buffer nil)
  ;; 	   (buffer (switch-to-buffer (org-export-as 'html nil nil t nil)))
  ;; 	   (rtn (buffer-substring (point-min) (point-max))))
  ;;     (kill-buffer buffer)
  ;;     rtn)))


;; This is used for the index-making function.
(defun ttlaxia-org-date-to-proper-date (date)
  "Given a string like 2012-10-05, return a string like May 5, 2012."
  (concat
   (let ((month (substring date 5 7)))
   (cond					;why doesn't `case' work for strings?
    ((string-equal month "01") "January")
    ((string-equal month "02") "February")
    ((string-equal month "03") "March")
    ((string-equal month "04") "April")
    ((string-equal month "05") "May")
    ((string-equal month "06") "June")
    ((string-equal month "07") "July")
    ((string-equal month "08") "August")
    ((string-equal month "09") "September")
    ((string-equal month "10") "October")
    ((string-equal month "11") "November")
    ((string-equal month "12") "December")))
   " "
   (number-to-string (string-to-number (substring date 8 10)))
   ", "
   (substring date 0 4)))

(defun ttlaxia-make-index (db)
  (setq output nil)
  (setq output
	(concat (dolist (post db output)
		  (setq output
			(concat output
				"&mdash;"
				(ttlaxia-org-date-to-proper-date (post-date post))
				"<br />\n<a href=\""
				(file-name-nondirectory (post-url post)) "\">"
				(post-title post) "</a>"
				"<br />"))))))

(defun ttlaxia-make-entry-links (author url source post)
  (concat  "<div id=\"entry-links\">"
	   "By <a href=\"" ttlaxia-author-web "\">" author "</a> | "
	   (ttlaxia-this-page-tags-links post) "<br />"
	   "<a href=\"" ttlaxia-homepage-name "\">Home</a> | "
	   "<a href=\"" url "\">Permalink</a> | "
	   "<a href=\"" (file-name-nondirectory source) "\">src</a> | "
	   "<a href=\""
	   (file-name-nondirectory
	    (file-name-sans-extension source))
	   ".tex"
	   "\">TeX</a> | "
	   "<a href=\""
	   (file-name-nondirectory
	    (file-name-sans-extension source))
	   ".pdf" "\">pdf</a>"
	   " | <a href=\"" ttlaxia-feed-name "\">"
	   "<img src=\"feed.gif\" title=\"Atom feed\" alt=\"Atom feed\" width=\"12\" height=\"12\" /></a><br />"
	   ttlaxia-addtoany-script
	   "</div>"))

(defun ttlaxia-make-homepage-links ()
  (concat
   "<a href=\"" ttlaxia-author-web "\"><img src=\"thorne.jpg\" alt=\"me\" title=\"Me\" /></a><br />"
   ttlaxia-feed-button "&nbsp;Site atom feed</a><br />"
   "<a href=\"ttlaxia.html\"><img src=\"question.png\" title=\"About\" alt=\"About\" height=\"12\" width=\"12\" />&nbsp;About&nbsp;Ttlåxia-Verlag</a><br /> "
   "<a href=\"ehwinner.html\"><img src=\"mail.png\" title=\"Contact info\" alt=\"Contact info\" height=\"12\" width=\"12\" />&nbsp;Contact</a><br />"
   "<a href=\"copying.html\"><img src=\"copyright.jpg\" title=\"Copyright\" alt=\"Copyright\" height=\"12\" width=\"12\" />&nbsp;Copyright</a><br />"
;   ttlaxia-addtoany-script
   ;; ttlaxia-addtoany-script "<br />"
   "&nbsp;<br />"))

(defun ttlaxia-make-homepage (db)
  (interactive)
  (save-excursion
    (with-temp-buffer
      (insert ttlaxia-homepage-html-header)
      (insert (concat "<div id=\"index\">\n"
		      (ttlaxia-make-homepage-links)
		      "<em><b>Most common tags—</b></em><br />"
		      (ttlaxia-do-tags-list db 'ttlaxia-has-more-tags-p 10) "<br /><br />"
		      "<em><b>Chronologic index—</b></em><br />\n"))
       (insert (ttlaxia-make-index db))
      (insert "\n</div>\n")
      (insert (concat "<div id=\"content\"><div id=\"thetitle\"><h1>"
		      ttlaxia-blog-title "</h1>"
		      ttlaxia-blog-subtitle "<br />"		
		      "</div>"))
      (insert
       (concat
	"<br /><em>Latest&mdash;</em>\n"))
      (dolist (post (first-n db ttlaxia-homepage-length))
	(insert (concat "<div id=\"entry\">"
			"<div id=\"entry-title\"><h1>"
			"<a href=\"" (post-url post) "\">"
			(post-title post) "</a></h1>"
			(ttlaxia-org-date-to-proper-date (post-date post))
			"</div>"
			(ttlaxia-make-entry-links (post-author post)
						  (post-url post)
						  (post-source post)
						  post)
			"<div id=\"entry-content\">"
			(ttlaxia-render-one (post-source post))
			"</div>"
			"<div class=\"hr\"><hr /></div>\n</div>")))
      (insert "</div>\n")
      (insert ttlaxia-homepage-html-footer)
      (ttlaxia-write-file
       (expand-file-name (concat ttlaxia-target-dir ttlaxia-homepage-name))
       nil)
      )))


;;; The individual pages

;; Permalinks.  Originally I used org-publish for this, but there are
;; too many things I want done my way, so I am going to just build
;; them all, every time.  Crazy?  Yes.

(defun ttlaxia-make-prev/next-links (prev next)
  (let ((prev-url (if prev (post-url prev) ""))
	(prev-title (if prev (post-title prev) ""))
	(next-url (if next (post-url next) ""))
	(next-title (if next (post-title next) "")))
    (concat "<span id=\"arrows\"><a href=\""
	    (file-name-nondirectory prev-url)
	    "\" title=\"" (file-name-nondirectory prev-title) "\"> "
	    "☚&nbsp;"
	    "</a>"
	    "<a href=\""
	    ttlaxia-homepage-name
	    ;; was ☝
	    "\" title=\"Home\">&nbsp;<img src=\"imprint.png\" />&nbsp;</a>"
	    "<a href=\"" (file-name-nondirectory next-url) "\" "
	    "title=\"" (file-name-nondirectory next-title) "\">"
	    "&nbsp;☛</a></span>")))

(defun ttlaxia-this-page-tags-links (this-post)
  (setq acc "Tags:")
  (dolist (tag (post-tags post))
    (setq acc (concat acc "<a href=\"tags.html#" tag "\"><em> " tag "</em></a>")))
  (concat acc "."))

(defun ttlaxia-make-permalink (post db)
  (let ((prev (ttlaxia-find-previous-post post db))
	(next (ttlaxia-find-next-post post db)))
    (with-temp-buffer
      (insert ttlaxia-homepage-html-header)
      (insert (concat "<div id=\"home\" align=\"right\">"
		      (ttlaxia-make-prev/next-links prev next)
		      "<br />"
		      "</div>"
		      ;; "<img src=\"home.png\" alt=\"Home\" height=\"12\" width=\"12\" /></a>&nbsp;"
		      ;; ttlaxia-feed-button "&nbsp;</div>"
		      ;; ttlaxia-addtoany-script
		      "<div id=\"content\"><div id=\"entry\">"
		      "<div id=\"entry-title\"><h1>"
		      "<a href=\"" (post-url post) "\">"
		      (post-title post) "</a></h1>"
		      (ttlaxia-org-date-to-proper-date (post-date post))
		      "</div>"
		      (ttlaxia-make-entry-links (post-author post)
						(post-url post)
						(post-source post)
						post)
		      "<div id=\"entry-content\">"
		      (ttlaxia-render-one (post-source post))
		      "</div>"))
      (insert "</div><div id=\"home\" align=\"right\">"
	      (ttlaxia-make-prev/next-links prev next)
	      "</div><br />"
	      ttlaxia-adsense-blob
	      ttlaxia-disqus-blob "</div>\n")
      (insert ttlaxia-homepage-html-footer)
      (ttlaxia-write-file
       (expand-file-name (concat
			  ttlaxia-target-dir
			  (file-name-nondirectory
			   (post-rendered post))))
       nil))))

(defun ttlaxia-make-one-permalink (file db)
  "Query for an individual file to render.  Use this for a new
post, then `ttlaxia-make-atom-feed' and `ttlaxia-make-homepage'
and then `org-publish' to publish project ttlaxia and then you
can use rsync to just upload the changed stuff."
  (interactive "fFile to render: ")	;what?  need to query for the
					;db too, I guess
  (ttlaxia-make-permalink (ttlaxia-make-post file) db))

(defun ttlaxia-make-permalinks (db)
  (interactive)
  (save-excursion
    (dolist (post db)
      (ttlaxia-make-permalink post db))))


;;; The atom feed

(defun ttlaxia-reset-feed ()
  "Clear the atom feed before re-running the render process."
  (setq ttlaxia-feed
	(atom-create
	 ttlaxia-blog-title
	 ttlaxia-base-url
	 ttlaxia-blog-subtitle
	 (concat ttlaxia-base-url ttlaxia-feed-name)
	 nil
	 ttlaxia-author)))

(defun ttlaxia-atom-add-xhtml-entry (post)
  (atom-add-entry 
   ttlaxia-feed 
   (post-title post) 
   (post-url post) 
   (ttlaxia-render-one (post-source post)) 
   (org-time-string-to-time (post-date post))
   nil
   (post-description post)))
;   t))

(defun ttlaxia-make-feed (db)
  "Create an atom feed for the blog."
  ;; First clear it in case it was already tried today.
  (ttlaxia-reset-feed)
  (dolist (post (first-n db ttlaxia-feed-length))
    (print post)
    (ttlaxia-atom-add-xhtml-entry post)))

(defun ttlaxia-make-atom-feed (db)
  (interactive)
  (ttlaxia-make-feed db)
  (atom-write-file ttlaxia-feed
		   (expand-file-name
		    (concat ttlaxia-target-dir ttlaxia-feed-name))))

(defun ttlaxia-prepare-db ()
  (interactive)
  (setq ttlaxia-blog (ttlaxia-make-db)))

;(ttlaxia-make-atom-feed (ttlaxia-prepare-db))
;(ttlaxia-make-feed (ttlaxia-prepare-db))

(defun ttlaxia-render-all ()
  "Build everything from scratch."
  (interactive)
;  (shell-command (concat "copy \"" (expand-file-name "~/cloud/ttlaxia/ttlaxia/ttlaxia.el") "\""
;  " \"" (expand-file-name "~/cloud/ttlaxia/ttlaxia/ttlaxia.el") "\"")) ;this file
  (org-publish "ttlaxia")
  (ttlaxia-prepare-db)
  (ttlaxia-make-atom-feed ttlaxia-blog)
  (ttlaxia-make-homepage ttlaxia-blog)
  (ttlaxia-make-tags-page ttlaxia-blog)
  (ttlaxia-make-permalinks ttlaxia-blog)
  (message "Success.  Don't forget to check and upload."))

(defun ttlaxia-add-new-entry (file)
  "Query for the source file name of a new entry.  Build
permalink, homepage, atom feed, TeX and pdf."
  (interactive "fFile name of new post: ")
  (ttlaxia-prepare-db)
  (ttlaxia-make-one-permalink file ttlaxia-blog)
  (org-publish "ttlaxia")
  (ttlaxia-make-atom-feed ttlaxia-blog)
  (ttlaxia-make-homepage ttlaxia-blog)
  (ttlaxia-make-tags-page ttlaxia-blog)
  (message "Success.  Don't forget to check and upload."))

 
;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Convenience functions

(defun ttlaxia-embed-pdf-fun (pdf-file)
  (concat; "#+BEGIN_HTML\n"
	  "<iframe src=\"http://docs.google.com/gview?url=http://ttlaxia.net/"
	  pdf-file
	  "&embedded=true\" style=\"width:25em; height:38em;\" frameborder=\"0\"></iframe>\n"
	 ; "#+END_HTML\n"
	  ))

(defun ttlaxia-embed-pdf (pdf-file)
  (interactive "fFile name: ")
  (insert (concat
	   "#+BEGIN_SRC emacs-lisp :exports results :results value html\n"
	   "(ttlaxia-embed-pdf-fun \"" (file-name-nondirectory pdf-file) "\")\n"
	   "#+END_SRC")))

;; This is for those ascii/css-art cartouches around links.
(defun ttlaxia-insert-cartouche-end ()
  (interactive)
  (insert "┫"))
