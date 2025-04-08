;; Education Verification Contract
;; This contract confirms academic degrees and training

;; Define data variables
(define-data-var contract-owner principal tx-sender)
(define-map educational-institutions principal bool)
(define-map education-records
  { id: (string-ascii 36) }
  {
    student: principal,
    institution: principal,
    degree: (string-ascii 100),
    field: (string-ascii 100),
    graduation-date: (string-ascii 10),
    verified: bool,
    timestamp: uint
  }
)

(define-map training-records
  { id: (string-ascii 36) }
  {
    participant: principal,
    provider: principal,
    course: (string-ascii 100),
    completion-date: (string-ascii 10),
    verified: bool,
    timestamp: uint
  }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ALREADY_REGISTERED u2)
(define-constant ERR_NOT_FOUND u3)
(define-constant ERR_ALREADY_VERIFIED u4)

;; Register an educational institution
(define-public (register-institution)
  (begin
    (asserts! (is-none (map-get? educational-institutions tx-sender)) (err ERR_ALREADY_REGISTERED))
    (ok (map-set educational-institutions tx-sender true))
  )
)

;; Approve an educational institution
(define-public (approve-institution (institution principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR_UNAUTHORIZED))
    (ok (map-set educational-institutions institution true))
  )
)

;; Add an education record
(define-public (add-education-record
    (id (string-ascii 36))
    (student principal)
    (degree (string-ascii 100))
    (field (string-ascii 100))
    (graduation-date (string-ascii 10))
  )
  (let (
    (record-exists (map-get? education-records {id: id}))
    (is-institution (default-to false (map-get? educational-institutions tx-sender)))
  )
    (asserts! (is-none record-exists) (err ERR_ALREADY_REGISTERED))
    (asserts! is-institution (err ERR_UNAUTHORIZED))
    (ok (map-set education-records
      {id: id}
      {
        student: student,
        institution: tx-sender,
        degree: degree,
        field: field,
        graduation-date: graduation-date,
        verified: true,
        timestamp: block-height
      }
    ))
  )
)

;; Add a training record
(define-public (add-training-record
    (id (string-ascii 36))
    (participant principal)
    (course (string-ascii 100))
    (completion-date (string-ascii 10))
  )
  (let (
    (record-exists (map-get? training-records {id: id}))
    (is-institution (default-to false (map-get? educational-institutions tx-sender)))
  )
    (asserts! (is-none record-exists) (err ERR_ALREADY_REGISTERED))
    (asserts! is-institution (err ERR_UNAUTHORIZED))
    (ok (map-set training-records
      {id: id}
      {
        participant: participant,
        provider: tx-sender,
        course: course,
        completion-date: completion-date,
        verified: true,
        timestamp: block-height
      }
    ))
  )
)

;; Get education record
(define-read-only (get-education-record (id (string-ascii 36)))
  (let ((record (map-get? education-records {id: id})))
    (if (is-some record)
      (ok (unwrap! record (err ERR_NOT_FOUND)))
      (err ERR_NOT_FOUND)
    )
  )
)

;; Get training record
(define-read-only (get-training-record (id (string-ascii 36)))
  (let ((record (map-get? training-records {id: id})))
    (if (is-some record)
      (ok (unwrap! record (err ERR_NOT_FOUND)))
      (err ERR_NOT_FOUND)
    )
  )
)

;; Verify if a person has a specific degree
(define-read-only (verify-degree (student principal) (degree (string-ascii 100)) (field (string-ascii 100)))
  (ok true)
  ;; In a real implementation, this would search through records to find a match
  ;; Simplified for this example
)
