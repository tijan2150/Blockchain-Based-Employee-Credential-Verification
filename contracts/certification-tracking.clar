;; Certification Tracking Contract
;; This contract records professional qualifications

;; Define data variables
(define-data-var contract-owner principal tx-sender)
(define-map certification-authorities principal bool)
(define-map certifications
  { id: (string-ascii 36) }
  {
    holder: principal,
    issuer: principal,
    name: (string-ascii 100),
    issue-date: (string-ascii 10),
    expiry-date: (string-ascii 10),
    verified: bool,
    timestamp: uint
  }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ALREADY_REGISTERED u2)
(define-constant ERR_NOT_FOUND u3)
(define-constant ERR_ALREADY_VERIFIED u4)
(define-constant ERR_EXPIRED u5)

;; Register as a certification authority
(define-public (register-authority)
  (begin
    (asserts! (is-none (map-get? certification-authorities tx-sender)) (err ERR_ALREADY_REGISTERED))
    (ok (map-set certification-authorities tx-sender true))
  )
)

;; Approve a certification authority
(define-public (approve-authority (authority principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR_UNAUTHORIZED))
    (ok (map-set certification-authorities authority true))
  )
)

;; Issue a certification
(define-public (issue-certification
    (id (string-ascii 36))
    (holder principal)
    (name (string-ascii 100))
    (issue-date (string-ascii 10))
    (expiry-date (string-ascii 10))
  )
  (let (
    (cert-exists (map-get? certifications {id: id}))
    (is-authority (default-to false (map-get? certification-authorities tx-sender)))
  )
    (asserts! (is-none cert-exists) (err ERR_ALREADY_REGISTERED))
    (asserts! is-authority (err ERR_UNAUTHORIZED))
    (ok (map-set certifications
      {id: id}
      {
        holder: holder,
        issuer: tx-sender,
        name: name,
        issue-date: issue-date,
        expiry-date: expiry-date,
        verified: true,
        timestamp: block-height
      }
    ))
  )
)

;; Renew a certification
(define-public (renew-certification
    (id (string-ascii 36))
    (new-expiry-date (string-ascii 10))
  )
  (let (
    (cert (unwrap! (map-get? certifications {id: id}) (err ERR_NOT_FOUND)))
    (is-issuer (is-eq tx-sender (get issuer cert)))
  )
    (asserts! is-issuer (err ERR_UNAUTHORIZED))
    (ok (map-set certifications
      {id: id}
      (merge cert {expiry-date: new-expiry-date})
    ))
  )
)

;; Revoke a certification
(define-public (revoke-certification (id (string-ascii 36)))
  (let (
    (cert (unwrap! (map-get? certifications {id: id}) (err ERR_NOT_FOUND)))
    (is-issuer (is-eq tx-sender (get issuer cert)))
  )
    (asserts! is-issuer (err ERR_UNAUTHORIZED))
    (ok (map-delete certifications {id: id}))
  )
)

;; Get certification details
(define-read-only (get-certification (id (string-ascii 36)))
  (let ((cert (map-get? certifications {id: id})))
    (if (is-some cert)
      (ok (unwrap! cert (err ERR_NOT_FOUND)))
      (err ERR_NOT_FOUND)
    )
  )
)

;; Check if a certification is valid (not expired)
(define-read-only (is-certification-valid (id (string-ascii 36)))
  (let ((cert (map-get? certifications {id: id})))
    (if (is-some cert)
      ;; In a real implementation, this would compare the expiry date with the current date
      ;; Simplified for this example
      (ok true)
      (err ERR_NOT_FOUND)
    )
  )
)

;; Get all certifications for a holder
;; Note: In a real implementation, this would require pagination or other mechanisms
;; Simplified for this example
(define-read-only (get-holder-certifications (holder principal))
  (ok true)
  ;; In a real implementation, this would search through records to find all matches
  ;; Simplified for this example
)
