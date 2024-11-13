;; PerpetuaFund: A Yield-Bearing Charity Fund

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-enough-funds (err u101))
(define-constant err-charity-not-found (err u102))
(define-constant err-already-voted (err u103))
(define-constant err-transfer-failed (err u104))

;; Data Variables
(define-data-var total-pool-balance uint u0)
(define-data-var total-yield uint u0)
(define-map donations principal uint)
(define-map charities {name: (string-ascii 64)} {address: principal, votes: uint})
(define-map votes {charity: (string-ascii 64), voter: principal} bool)

;; Private Functions
(define-private (transfer-yield (recipient principal) (amount uint))
  (match (as-contract (stx-transfer? amount tx-sender recipient))
    success (ok amount)
    error (err u1)
  )
)

;; Public Functions
(define-public (donate)
  (let ((amount (stx-get-balance tx-sender)))
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set donations tx-sender (+ (default-to u0 (map-get? donations tx-sender)) amount))
    (var-set total-pool-balance (+ (var-get total-pool-balance) amount))
    (ok amount)
  )
)

(define-public (generate-yield)
  (let (
    (new-yield (/ (* (var-get total-pool-balance) u5) u100)) ;; 5% yield for simulation
  )
    (var-set total-yield (+ (var-get total-yield) new-yield))
    (ok new-yield)
  )
)

(define-public (distribute-yield (charity (string-ascii 64)))
  (let (
    (charity-info (unwrap! (map-get? charities {name: charity}) (err err-charity-not-found)))
    (yield-amount (var-get total-yield))
  )
    (match (transfer-yield (get address charity-info) yield-amount)
      success (begin
        (var-set total-yield u0)
        (ok yield-amount)
      )
      error (err err-transfer-failed)
    )
  )
)

(define-read-only (view-balance)
  (ok {
    total-pool: (var-get total-pool-balance),
    current-yield: (var-get total-yield)
  })
)

(define-public (add-charity (name (string-ascii 64)) (address principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set charities {name: name} {address: address, votes: u0})
    (ok true)
  )
)

(define-public (vote-for-charity (name (string-ascii 64)))
  (let (
    (has-voted (default-to false (map-get? votes {charity: name, voter: tx-sender})))
    (current-votes (get votes (unwrap! (map-get? charities {name: name}) err-charity-not-found)))
  )
    (asserts! (not has-voted) err-already-voted)
    (map-set votes {charity: name, voter: tx-sender} true)
    (map-set charities {name: name} 
      (merge (unwrap! (map-get? charities {name: name}) err-charity-not-found)
             {votes: (+ u1 current-votes)}))
    (ok true)
  )
)

;; Read-only functions for transparency
(define-read-only (get-donation (donor principal))
  (ok (default-to u0 (map-get? donations donor)))
)

(define-read-only (get-charity-info (name (string-ascii 64)))
  (ok (unwrap! (map-get? charities {name: name}) err-charity-not-found))
)

(define-read-only (get-total-donations)
  (ok (var-get total-pool-balance))
)

(define-read-only (get-total-yield)
  (ok (var-get total-yield))
)