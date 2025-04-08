;; Identity Verification Contract
;; This contract validates personal information of employees

;; Define data variables
(define-data-var contract-owner principal tx-sender)
(define-map identities
  { id: (string-ascii 36) }
  {
    owner: principal,
    name: (string-ascii 100),
    date-of-birth: (string-ascii 10),
    government-id: (buff 32),
    verified: bool,
    timestamp: uint
  }
)

(define-map verifiers principal bool)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ALREADY_REGISTERED u2)
(define-constant ERR_NOT_FOUND u3)
(define-constant ERR_ALREADY_VERIFIED u4)

;; Add a verifier who can validate identities
(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR_UNAUTHORIZED))
    (ok (map-set verifiers verifier true))
  )
)

;; Remove a verifier
(define-public (remove-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR_UNAUTHORIZED))
    (ok (map-delete verifiers verifier))
  )
)

;; Register a new identity
(define-public (register-identity
    (id (string-ascii 36))
    (name (string-ascii 100))
    (date-of-birth (string-ascii 10))
    (government-id (buff 32))
  )
  (let ((identity-data (map-get? identities {id: id})))
    (asserts! (is-none identity-data) (err ERR_ALREADY_REGISTERED))
    (ok (map-set identities
      {id: id}
      {
        owner: tx-sender,
        name: name,
        date-of-birth: date-of-birth,
        government-id: government-id,
        verified: false,
        timestamp: block-height
      }
    ))
  )
)

;; Verify an identity
(define-public (verify-identity (id (string-ascii 36)))
  (let (
    (identity-data (unwrap! (map-get? identities {id: id}) (err ERR_NOT_FOUND)))
    (is-verifier (default-to false (map-get? verifiers tx-sender)))
  )
    (asserts! is-verifier (err ERR_UNAUTHORIZED))
    (asserts! (not (get verified identity-data)) (err ERR_ALREADY_VERIFIED))
    (ok (map-set identities
      {id: id}
      (merge identity-data {verified: true})
    ))
  )
)

;; Get identity information (only owner or verifier can access)
(define-read-only (get-identity (id (string-ascii 36)))
  (let (
    (identity-data (unwrap! (map-get? identities {id: id}) (err ERR_NOT_FOUND)))
    (is-verifier (default-to false (map-get? verifiers tx-sender)))
    (is-owner (is-eq tx-sender (get owner identity-data)))
  )
    (asserts! (or is-owner is-verifier) (err ERR_UNAUTHORIZED))
    (ok identity-data)
  )
)

;; Check if an identity is verified (public function)
(define-read-only (is-identity-verified (id (string-ascii 36)))
  (let ((identity-data (map-get? identities {id: id})))
    (if (is-some identity-data)
      (ok (get verified (unwrap! identity-data (err ERR_NOT_FOUND))))
      (err ERR_NOT_FOUND)
    )
  )
)
