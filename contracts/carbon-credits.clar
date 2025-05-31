;; Forest Carbon Credits Contract
;; Manages carbon credit issuance and trading for forest conservation projects

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-invalid-project-name (err u104))
(define-constant err-invalid-project-id (err u105))
(define-constant err-project-not-verified (err u106))

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

;; Input validation functions
(define-private (is-valid-project-name (name (string-ascii 50)))
  (and (> (len name) u0) (<= (len name) u50))
)

(define-private (is-valid-project-id (project-id uint))
  (and (> project-id u0) (< project-id (var-get next-project-id)))
)

(define-private (project-exists (project-id uint))
  (is-some (map-get? carbon-credits { project-id: project-id }))
)

(define-public (register-forest-project (project-name (string-ascii 50)) (initial-credits uint))
  (let ((project-id (var-get next-project-id)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> initial-credits u0) err-invalid-amount)
    (asserts! (is-valid-project-name project-name) err-invalid-project-name)

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
    (asserts! (is-valid-project-id project-id) err-invalid-project-id)
    (asserts! (project-exists project-id) err-not-found)

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
    (asserts! (is-valid-project-id project-id) err-invalid-project-id)
    (asserts! (project-exists project-id) err-not-found)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (get verification-status project) err-project-not-verified)
    (asserts! (>= (get credits-available project) amount) err-insufficient-balance)

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

;; Transfer credits between users
(define-public (transfer-credits (to principal) (project-id uint) (amount uint))
  (let (
    (sender-balance (get-user-balance tx-sender project-id))
    (recipient-balance (get-user-balance to project-id))
  )
    (asserts! (is-valid-project-id project-id) err-invalid-project-id)
    (asserts! (project-exists project-id) err-not-found)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (>= sender-balance amount) err-insufficient-balance)
    (asserts! (not (is-eq tx-sender to)) err-invalid-amount)

    (map-set user-balances 
      { user: tx-sender, project-id: project-id }
      { balance: (- sender-balance amount) }
    )

    (map-set user-balances 
      { user: to, project-id: project-id }
      { balance: (+ recipient-balance amount) }
    )
    (ok amount)
  )
)

;; Read-only functions
(define-read-only (get-project-info (project-id uint))
  (map-get? carbon-credits { project-id: project-id })
)

(define-read-only (get-user-balance (user principal) (project-id uint))
  (default-to u0 (get balance (map-get? user-balances { user: user, project-id: project-id })))
)

(define-read-only (get-total-projects)
  (- (var-get next-project-id) u1)
)

(define-read-only (is-project-verified (project-id uint))
  (match (map-get? carbon-credits { project-id: project-id })
    project (get verification-status project)
    false
  )
)

(define-read-only (get-available-credits (project-id uint))
  (match (map-get? carbon-credits { project-id: project-id })
    project (get credits-available project)
    u0
  )
)