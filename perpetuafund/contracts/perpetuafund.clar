;; PerpetuaFund: A Yield-Bearing Charity Fund with Customizable Inheritance Tiers and Time-Locked Notifications

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-enough-funds (err u101))
(define-constant err-charity-not-found (err u102))
(define-constant err-already-voted (err u103))
(define-constant err-transfer-failed (err u104))
(define-constant err-invalid-tier (err u105))
(define-constant err-beneficiary-not-found (err u106))
(define-constant err-not-beneficiary (err u107))
(define-constant err-not-unlocked (err u108))

;; Data Variables
(define-data-var total-pool-balance uint u0)
(define-data-var total-yield uint u0)
(define-data-var last-activity-time uint u0)
(define-map donations principal uint)
(define-map charities {name: (string-ascii 64)} {address: principal, votes: uint})
(define-map votes {charity: (string-ascii 64), voter: principal} bool)
(define-map inheritance-tiers 
  {owner: principal, tier: uint} 
  {inactivity-period: uint, beneficiary: principal, percentage: uint, last-notification: uint}
)
(define-map beneficiary-notifications 
  {beneficiary: principal, owner: principal} 
  {tier: uint, unlock-time: uint, notified: bool}
)

;; Private Functions
(define-private (transfer-yield (recipient principal) (amount uint))
  (match (as-contract (stx-transfer? amount tx-sender recipient))
    success (ok amount)
    error (err err-transfer-failed)
  )
)

(define-private (update-activity)
  (var-set last-activity-time block-height)
)

;; Public Functions
(define-public (donate)
  (let ((amount (stx-get-balance tx-sender)))
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set donations tx-sender (+ (default-to u0 (map-get? donations tx-sender)) amount))
    (var-set total-pool-balance (+ (var-get total-pool-balance) amount))
    (update-activity)
    (ok amount)
  )
)

(define-public (generate-yield)
  (let (
    (new-yield (/ (* (var-get total-pool-balance) u5) u100)) ;; 5% yield for simulation
  )
    (var-set total-yield (+ (var-get total-yield) new-yield))
    (update-activity)
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
        (update-activity)
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
    (update-activity)
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
    (update-activity)
    (ok true)
  )
)

;; Inheritance Tier Management
(define-public (set-inheritance-tier (tier uint) (inactivity-period uint) (beneficiary principal) (percentage uint))
  (begin
    (asserts! (and (>= tier u1) (<= tier u3)) err-invalid-tier)
    (asserts! (<= percentage u100) err-invalid-tier)
    (map-set inheritance-tiers {owner: tx-sender, tier: tier} 
      {inactivity-period: inactivity-period, beneficiary: beneficiary, percentage: percentage, last-notification: u0})
    (update-activity)
    (ok true)
  )
)

(define-public (remove-inheritance-tier (tier uint))
  (begin
    (asserts! (and (>= tier u1) (<= tier u3)) err-invalid-tier)
    (map-delete inheritance-tiers {owner: tx-sender, tier: tier})
    (update-activity)
    (ok true)
  )
)

(define-read-only (get-inheritance-tier (owner principal) (tier uint))
  (match (map-get? inheritance-tiers {owner: owner, tier: tier})
    tier-info (ok tier-info)
    (err err-beneficiary-not-found)
  )
)

(define-private (distribute-inheritance (owner principal) (beneficiary principal) (percentage uint) (total-balance uint))
  (let (
    (amount-to-transfer (/ (* total-balance percentage) u100))
  )
    (match (as-contract (stx-transfer? amount-to-transfer tx-sender beneficiary))
      success (begin
        (var-set total-pool-balance (- total-balance amount-to-transfer))
        (map-delete donations owner)
        (map-delete inheritance-tiers {owner: owner, tier: u1})
        (map-delete inheritance-tiers {owner: owner, tier: u2})
        (map-delete inheritance-tiers {owner: owner, tier: u3})
        (map-delete beneficiary-notifications {beneficiary: beneficiary, owner: owner})
        (ok amount-to-transfer)
      )
      error (err err-transfer-failed)
    )
  )
)

;; Time-Locked Notifications for Beneficiaries
(define-public (check-and-notify-beneficiaries)
  (let (
    (current-time block-height)
    (last-activity (var-get last-activity-time))
  )
    (map-set beneficiary-notifications 
      {beneficiary: tx-sender, owner: contract-owner}
      (merge 
        (default-to 
          {tier: u0, unlock-time: u0, notified: false}
          (map-get? beneficiary-notifications {beneficiary: tx-sender, owner: contract-owner})
        )
        {
          tier: (get-highest-eligible-tier tx-sender contract-owner current-time last-activity),
          unlock-time: (+ last-activity (get-inactivity-period tx-sender contract-owner)),
          notified: true
        }
      )
    )
    (ok true)
  )
)

(define-private (get-highest-eligible-tier (beneficiary principal) (owner principal) (current-time uint) (last-activity uint))
  (let (
    (tier-1 (default-to {inactivity-period: u0, beneficiary: 'SP000000000000000000002Q6VF78, percentage: u0, last-notification: u0} 
              (map-get? inheritance-tiers {owner: owner, tier: u1})))
    (tier-2 (default-to {inactivity-period: u0, beneficiary: 'SP000000000000000000002Q6VF78, percentage: u0, last-notification: u0} 
              (map-get? inheritance-tiers {owner: owner, tier: u2})))
    (tier-3 (default-to {inactivity-period: u0, beneficiary: 'SP000000000000000000002Q6VF78, percentage: u0, last-notification: u0} 
              (map-get? inheritance-tiers {owner: owner, tier: u3})))
  )
    (if (and (is-eq beneficiary (get beneficiary tier-3)) (>= (- current-time last-activity) (get inactivity-period tier-3)))
      u3
      (if (and (is-eq beneficiary (get beneficiary tier-2)) (>= (- current-time last-activity) (get inactivity-period tier-2)))
        u2
        (if (and (is-eq beneficiary (get beneficiary tier-1)) (>= (- current-time last-activity) (get inactivity-period tier-1)))
          u1
          u0
        )
      )
    )
  )
)

(define-private (get-inactivity-period (beneficiary principal) (owner principal))
  (let (
    (tier-1 (default-to {inactivity-period: u0, beneficiary: 'SP000000000000000000002Q6VF78, percentage: u0, last-notification: u0} 
              (map-get? inheritance-tiers {owner: owner, tier: u1})))
    (tier-2 (default-to {inactivity-period: u0, beneficiary: 'SP000000000000000000002Q6VF78, percentage: u0, last-notification: u0} 
              (map-get? inheritance-tiers {owner: owner, tier: u2})))
    (tier-3 (default-to {inactivity-period: u0, beneficiary: 'SP000000000000000000002Q6VF78, percentage: u0, last-notification: u0} 
              (map-get? inheritance-tiers {owner: owner, tier: u3})))
  )
    (if (is-eq beneficiary (get beneficiary tier-3))
      (get inactivity-period tier-3)
      (if (is-eq beneficiary (get beneficiary tier-2))
        (get inactivity-period tier-2)
        (if (is-eq beneficiary (get beneficiary tier-1))
          (get inactivity-period tier-1)
          u0
        )
      )
    )
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

(define-read-only (get-last-activity-time)
  (ok (var-get last-activity-time))
)

(define-read-only (get-beneficiary-notification (beneficiary principal) (owner principal))
  (ok (unwrap! (map-get? beneficiary-notifications {beneficiary: beneficiary, owner: owner}) err-not-beneficiary))
)