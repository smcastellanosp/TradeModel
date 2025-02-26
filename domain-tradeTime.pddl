(define (domain urbantraffic)
;;(:requirements :typing :fluents :time :timed-initial-literals :duration-inequalities :adl)

(:types junction link stage granularity)

(:predicates 
(controllable ?i - junction)
(inter ?p - stage)
(active ?p - stage)
(next ?p ?p1 - stage)
(trigger ?i - junction)
(contains ?i - junction ?p - stage)
(endcycle ?i - junction ?p - stage)
(ic ?p - stage ?i - junction)
(junctioninter ?i - junction)
)

(:functions 
(turnrate ?x - stage ?r1 - link  ?r2 - link) 
(interlimit ?p - stage)
(intertime ?i - junction)
(occupancy ?r - link) 
(capacity ?r - link) 
(defaultgreentime ?p - stage ) 
(greentime ?i - junction)
(counter ?r - link) 
(currentstage ?i - junction)
(stagenumber ?p - stage)
(tradegranularity ?g - granularity)
(swapcounter ?i - junction)
(swaplimit)
)

;; the maximum time limit for green has been reached, but no need to restart token!
(:event defgreenreached
 :parameters (?p - stage ?i - junction)
 :precondition (and 
	(active ?p) (contains ?i ?p)
	(>= (greentime ?i) (defaultgreentime ?p))
	)
  :effect (and
	(trigger ?i)
	)
)

;; process that keeps the green/intergreen on, and updates the greentime value
(:process keepgreen
:parameters (?p - stage ?i - junction)
:precondition (and 
		(active ?p) 
		(contains ?i ?p)
    (< (greentime ?i) (defaultgreentime ?p))
)
:effect (and
		(increase (greentime ?i) (* #t 1 ) )
))



;;allows car to flow if the corresponding green is on
(:process flowrun_green
:parameters (?p - stage ?r1 ?r2 - link)
:precondition (and 
		(active ?p)
		(> (occupancy ?r1) 0.0)
		(> (turnrate ?p ?r1 ?r2) 0.0)
		(< (occupancy ?r2) (capacity ?r2))
)
:effect (and
		(increase (occupancy ?r2) (* #t (turnrate ?p ?r1 ?r2)))
		(decrease (occupancy ?r1) (* #t (turnrate ?p ?r1 ?r2)))
    (increase (counter ?r2) (* #t (turnrate ?p ?r1 ?r2)))
))


;; 
(:action tradeTime
    :parameters (?p1 ?p2 - stage ?i - junction ?g - granularity)
    :precondition (and
        (controllable ?i)
        (junctioninter ?i)
        (contains ?i ?p1)
        (contains ?i ?p2)
        (not (= ?p1 ?p2))
        (< (swapcounter ?i) (swaplimit))
        (> (stagenumber ?p1) (currentstage ?i))
        (> (stagenumber ?p2) (currentstage ?i))
        (> (defaultgreentime ?p1) (tradegranularity ?g))
    )
    :effect (and 
        (decrease (defaultgreentime ?p1) (tradegranularity ?g))
        (increase (defaultgreentime ?p2) (tradegranularity ?g))
        (increase (swapcounter ?i) 1)
    )
)


(:process handle_time
:parameters()
:effect (and 
  (increase (time) (* #t 1 ))
  )
)


(:event trigger-inter
:parameters (?p - stage ?i - junction)
 :precondition (and
        (trigger ?i)
        (active ?p) 
        (contains ?i ?p)
        )
  :effect (and
        (not (trigger ?i))
        (not (active ?p))
        (inter ?p)
        (junctioninter ?i)
	      (assign (greentime ?i) 0)
        )
)


(:event reset_counters
:parameters (?p - stage ?i - junction)
 :precondition (and
        (ic ?p ?i)
        (endcycle ?i ?p)
        )
  :effect (and
        (not (ic ?p ?i))
        (assign (currentstage ?i) 0)
        (assign (swapcounter ?i) 0)
        )
)


(:process keepinter
  :parameters (?p - stage ?i - junction)
  :precondition (and 
      (inter ?p) 
      (contains ?i ?p)
      (< (intertime ?i) (interlimit ?p))
   )
   :effect (and
      (increase (intertime ?i) (* #t 1 ))
   ))


(:event trigger-change
:parameters (?p ?p1 - stage ?i - junction)
 :precondition (and 
   (inter ?p) 
   (contains ?i ?p)
   (next ?p ?p1)
   (>= (intertime ?i) (- (interlimit ?p) 0.1))
	)
  :effect (and
    (not (inter ?p))
    (not (junctioninter ?i))
    (active ?p1)
	  (assign (intertime ?i) 0)
	  (increase (currentstage ?i) 1)
	  (ic ?p ?i)
	)
)

)