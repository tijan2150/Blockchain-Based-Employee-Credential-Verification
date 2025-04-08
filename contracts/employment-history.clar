;; Employment History Contract
;; This contract validates previous work experience

;; Define data variables
(define-data-var contract-owner principal tx-sender)
(define-map employers principal bool)
(define-map employment-records
  { id: (string-ascii 36) }
  {
    employee: principal,
    employer: principal,
    title: (string-ascii 100),
    start-date: (string-ascii 10),
    end-date: (string-ascii 10),
    responsibilities: (string-ascii 500),
    verified: bool,
    timestamp: uint
  }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ALREADY_REGISTERED u2)
(define-constant ERR_NOT_FOUND u3)
(define-constant ERR_ALREADY_VERIFIED u4)

;; Register as an employer
(define-public (register-employer)
  (begin
    (asserts! (is-none (map-get? employers tx-sender)) (err ERR_ALREADY_REGISTERED))
    (ok (map-set employers tx-sender true))
  )
)

;; Approve an employer
(define-public (approve-employer (employer principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR_UNAUTHORIZED))
    (ok (map-set employers employer true))
  )
)

;; Add employment record
(define-public (add-employment-record
    (id (string-ascii 36))
    (employee principal)
    (title (string-ascii 100))
    (start-date (string-ascii 10))
    (end-date (string-ascii 10))
    (responsibilities (string-ascii 500))
  )
  (let (
    (record-exists (map-get? employment-records {id: id}))
    (is-employer (default-to false (map-get? employers tx-sender)))
  )
    (asserts! (is-none record-exists) (err ERR_ALREADY_REGISTERED))
    (asserts! is-employer (err ERR_UNAUTHORIZED))
    (ok (map-set employment-records
      {id: id}
      {
        employee: employee,
        employer: tx-sender,
        title: title,
        start-date: start-date,
        end-date: end-date,
        responsibilities: responsibilities,
        verified: true,
        timestamp: block-height
      }
    ))
  )
)

;; Employee can claim employment (to be verified by employer)
(define-public (claim-employment
    (id (string-ascii 36))
    (employer principal)
    (title (string-ascii 100))
    (start-date (string-ascii 10))
    (end-date (string-ascii 10))
    (responsibilities (string-ascii 500))
  )
  (let ((record-exists (map-get? employment-records {id: id})))
    (asserts! (is-none record-exists) (err ERR_ALREADY_REGISTERED))
    (ok (map-set employment-records
      {id: id}
      {
        employee: tx-sender,
        employer: employer,
        title: title,
        start-date: start-date,
        end-date: end-date,
        responsibilities: responsibilities,
        verified: false,
        timestamp: block-height
      }
    ))
  )
)

;; Employer verifies a claimed employment record
(define-public (verify-employment (id (string-ascii 36)))
  (let (
    (record (unwrap! (map-get? employment-records {id: id}) (err ERR_NOT_FOUND)))
    (is-employer (is-eq tx-sender (get employer record)))
  )
    (asserts! is-employer (err ERR_UNAUTHORIZED))
    (asserts! (not (get verified record)) (err ERR_ALREADY_VERIFIED))
    (ok (map-set employment-records
      {id: id}
      (merge record {verified: true})
    ))
  )
)

;; Get employment record
(define-read-only (get-employment-record (id (string-ascii 36)))
  (let ((record (map-get? employment-records {id: id})))
    (if (is-some record)
      (ok (unwrap! record (err ERR_NOT_FOUND)))
      (err ERR_NOT_FOUND)
    )
  )
)

;; Get all employment records for an employee
;; Note: In a real implementation, this would require pagination or other mechanisms
;; Simplified for this example
(define-read-only (get-employee-history (employee principal))
  (ok true)
  ;; In a real implementation, this would search through records to find all matches
  ;; Simplified for this example
)
