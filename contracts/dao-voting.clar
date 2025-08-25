;; ------------------------------------------------------------
;; DAO Voting with STX Weight
;; ------------------------------------------------------------
;; - Members deposit STX into the DAO vault
;; - Voting power = their balance
;; - Proposals can be created and voted on
;; - Each proposal has start/end block heights
;; - After deadline, proposal is finalized
;; ------------------------------------------------------------

;; ---------- Errors ----------
(define-constant ERR-NO-DEPOSIT     (err u100))
(define-constant ERR-NOT-FOUND      (err u101))
(define-constant ERR-ALREADY-VOTED  (err u102))
(define-constant ERR-TOO-EARLY      (err u103))
(define-constant ERR-TOO-LATE       (err u104))
(define-constant ERR-INVALID-INPUT  (err u105))

;; ---------- Data ----------
(define-data-var next-proposal-id uint u1)

(define-map balances
  { member: principal }
  { stx: uint })

(define-map proposals
  { id: uint }
  {
    creator: principal,
    title: (string-ascii 64),
    start: uint,
    end: uint,
    yes: uint,
    no: uint,
    executed: bool
  })

(define-map votes
  { id: uint, voter: principal }
  { choice: bool })





;; ---------- Deposit / Withdraw ----------
(define-public (deposit (amount uint))
  (begin
    (asserts! (> amount u0) ERR-NO-DEPOSIT)
    (unwrap! (stx-transfer? amount tx-sender (as-contract tx-sender)) ERR-NO-DEPOSIT)
    (let ((prev (default-to u0 (get stx (map-get? balances { member: tx-sender })))))
      (map-set balances { member: tx-sender } { stx: (+ prev amount) })
      (ok true))))

(define-public (withdraw (amount uint))
  (let ((bal (default-to u0 (get stx (map-get? balances { member: tx-sender })))))
    (asserts! (>= bal amount) ERR-NO-DEPOSIT)
    (map-set balances { member: tx-sender } { stx: (- bal amount) })
    (stx-transfer? amount (as-contract tx-sender) tx-sender)))

;; ---------- Proposals ----------
(define-public (create-proposal (title (string-ascii 64)) (duration uint))
  (begin
    (asserts! (> duration u0) ERR-NO-DEPOSIT)
    (asserts! (is-some (as-max-len? title u64)) ERR-INVALID-INPUT)
    (let ((id (var-get next-proposal-id))
          (start-height burn-block-height)
          (end-height (+ burn-block-height duration))
          (valid-title (unwrap! (as-max-len? title u64) ERR-INVALID-INPUT)))
      (asserts! (> id u0) ERR-INVALID-INPUT)
      (map-set proposals { id: id } {
          creator: tx-sender,
          title: valid-title,
          start: start-height,
          end: end-height,
          yes: u0,
          no: u0,
          executed: false
        })
      (var-set next-proposal-id (+ id u1))
      (ok id))))

;; ---------- Voting ----------
(define-public (vote (id uint) (support bool))
  (begin
    (asserts! (> id u0) ERR-INVALID-INPUT)
    (match (map-get? proposals { id: id })
      proposal (begin
        (asserts! (>= burn-block-height (get start proposal)) ERR-TOO-EARLY)
        (asserts! (< burn-block-height (get end proposal)) ERR-TOO-LATE)
        (asserts! (is-none (map-get? votes { id: id, voter: tx-sender })) ERR-ALREADY-VOTED)

        (let ((power (default-to u0 (get stx (map-get? balances { member: tx-sender }))))
              (old-yes (get yes proposal))
              (old-no (get no proposal)))
          (asserts! (> power u0) ERR-NO-DEPOSIT)
          (map-set proposals { id: id }
            (merge proposal 
              {
                yes: (if support (+ old-yes power) old-yes),
                no: (if support old-no (+ old-no power))
              }))
          (map-set votes { id: id, voter: tx-sender } { choice: support })
          (ok true)))
      ERR-NOT-FOUND)))

;; ---------- Finalize ----------
(define-public (finalize (id uint))
  (begin
    (asserts! (> id u0) ERR-INVALID-INPUT)
    (match (map-get? proposals { id: id })
      proposal (begin
        (asserts! (>= burn-block-height (get end proposal)) ERR-TOO-EARLY)
        (asserts! (not (get executed proposal)) ERR-ALREADY-VOTED)
        (map-set proposals { id: id } (merge proposal { executed: true }))
        (ok (if (>= (get yes proposal) (get no proposal)) true false)))
      ERR-NOT-FOUND)))
