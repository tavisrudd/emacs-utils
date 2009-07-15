;; parse-table-binder 
;; this code parses a table binder for clojure-like binding

(require 'cl)
(require 'utils)

(setq currently-defining-defn 'lambda)

(defun key->count-key (it)
  (case it 
	(:as :n-as) 
	(:or :n-or)
	(:keys :n-keys)))

(defun check-keys-form (form)
  (and (vectorp form)
	   (foldl 
		(lambda (it ac)
		  (and (not (keywordp it))
			   (symbolp it)
			   ac))
		t
		(vector->list form))))

(defun parse-tbl-special-forms (it ac)
  (let-tbl 
	((i :i)
	 (state :state)
	 (n-as :n-as)
	 (n-or :n-or)
	 (as-sym :as-sym)
	 (or-form :or-form)
	 (binders :binders)
	 (prev :prev)
	 (keys :keys)) ac
  (cond 
   ((oddp i)
	(if (or
		 (eq :keys it)
		 (eq :as it)
		 (eq :or it))
		(let* ((count-key (key->count-key it))
			   (n-special-form (+ 1 (tbl ac count-key))))
		  (if (> n-special-form 1) (error "More than one %s clause in table binder in %s." it currently-defining-defn))
		  (tbl! ac
				:prev it
				:i (+ i 1)
				count-key n-special-form))
	  (error "Unrecognized special form keyword %s in %s" it currently-defining-defn)))
   ((evenp i)
	(let ((spec-key (case prev (:as :as-sym) (:or :or-form) (:keys :keys-seq))))
	  (case prev
		(:keys 
		 (if (check-keys-form it)
			 (tbl! ac 
				   :i (+ i 1)
				   :prev it
				   spec-key it)
		   (error ":keys must be followed by a vector of symbols, got %s instead in %s." it currently-defining-defn)))
		(:as 
		 (if (symbolp it)
			 (tbl! ac
				   :i (+ i 1)
				   :prev it
				   spec-key it)
		   (error "As forms must be symbols.  Got %s instead in %s" it currently-defining-defn)))
		(:or 
		 (tbl! ac
			   :i (+ i 1)
			   :prev it
			   spec-key it))))))))

(defun parse-tbl-binders (it ac)
  (let-tbl 
	((i :i)
	 (state :state)
	 (n-as :n-as)
	 (n-or :n-or)
	 (as-sym :as-sym)
	 (or-form :or-form)
	 (binders :binders)
	 (n-keys :n-keys)
	 (keys-seq :keys-seq)
	 (keys :keys)) ac
	(cond
	 ((oddp i)
	  (if (not (keywordp it))
		  (tbl! ac
				:i (+ i 1)
				:prev it
				:binders (suffix binders it))
		(parse-tbl-special-forms
		 it
		 (tbl! ac 
			   :prev it
			   :state :parsing-special-forms))))
	 ((evenp i)
	  (tbl! ac
			:i (+ i 1)
			:prev it
			:keys (suffix keys it))))))
	 
	 
(defun parse-and-check-tbl-binder (binder)
  (let-tbl
   ((binders :binders)
	(keys    :keys)
	(as-sym  :as-sym)
	(or-form :or-form)
	(keys-seq :keys-seq))
   (foldl
	(lambda (it ac)
	  (let-tbl 
	   ((i :i)
		(state :state)
		(n-as :n-as)
		(n-or :n-or)
		(as-sym :as-sym)
		(or-form :or-form)
		(binders :binders)
		(keys :keys)) ac
	   (case state
		 (:parsing-binders 
		  (parse-tbl-binders it ac))
		 (:parsing-special-forms
		  (parse-tbl-special-forms it ac))
		 (:init
		  (if (eq it ::)
			  (tbl! ac
					:state :parsing-binders
					:prev it
					:i (+ i 1))
			(error "Hash-table binding forms must start with :: (%s)." currently-defining-defn))))))
	(tbl!
	 :i 0
	 :state :init
	 :n-as 0
	 :n-or 0
	 :n-keys 0
	 :as-sym nil
	 :or-form nil
	 :keys-seq nil
	 :prev nil
	 :binders '()
	 :keys '())
	(vector->list binder))
   (list binders keys as-sym or-form keys-seq)))

(comment
 (parse-and-check-tbl-binder [:: a :a b :b c :c :as all :or something :keys [q r s]]) )

(provide 'parse-table-binder)

	 