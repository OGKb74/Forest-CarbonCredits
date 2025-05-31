;; Forest Carbon Credits Contract
;; Manages carbon credit issuance and trading for forest conservation projects

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-invalid-amount (err u103))

(define-map carbon-credits 
  { project-id: uint } 
  { 
    owner: principal,
    credits-issued: uint,
    credits-available: uint,
    verification-status: bool,
    project-name: (string-ascii 50)
  }
)

(define-map user-balances 
  { user: principal, project-id: uint } 
  { balance: uint }
)

(define-data-var next-project-id uint u1)

(define-public (register-forest-project (project-name (string-ascii 50)) (initial-credits uint))
  (let ((project-id (var-get next-project-id)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> initial-credits u0) err-invalid-amount)
    (map-set carbon-credits 
      { project-id: project-id }
      {
        owner: tx-sender,
        credits-issued: initial-credits,
        credits-available: initial-credits,
        verification-status: false,
        project-name: project-name
      }
    )
    (var-set next-project-id (+ project-id u1))
    (ok project-id)
  )
)

(define-public (verify-project (project-id uint))
  (let ((project (unwrap! (map-get? carbon-credits { project-id: project-id }) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set carbon-credits 
      { project-id: project-id }
      (merge project { verification-status: true })
    )
    (ok true)
  )
)

(define-public (purchase-credits (project-id uint) (amount uint))
  (let (
    (project (unwrap! (map-get? carbon-credits { project-id: project-id }) err-not-found))
    (current-balance (default-to u0 (get balance (map-get? user-balances { user: tx-sender, project-id: project-id }))))
  )
    (asserts! (get verification-status project) err-not-found)
    (asserts! (>= (get credits-available project) amount) err-insufficient-balance)
    (asserts! (> amount u0) err-invalid-amount)

    (map-set carbon-credits 
      { project-id: project-id }
      (merge project { credits-available: (- (get credits-available project) amount) })
    )

    (map-set user-balances 
      { user: tx-sender, project-id: project-id }
      { balance: (+ current-balance amount) }
    )
    (ok amount)
  )
)

(define-read-only (get-project-info (project-id uint))
  (map-get? carbon-credits { project-id: project-id })
)

(define-read-only (get-user-balance (user principal) (project-id uint))
  (default-to u0 (get balance (map-get? user-balances { user: user, project-id: project-id })))
)

(define-read-only (get-total-projects)
  (- (var-get next-project-id) u1)
)
