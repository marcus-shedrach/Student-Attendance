;; Student Attendance Tracking Smart Contract
;; A comprehensive system for managing student attendance records

;; Constants for error handling
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-STUDENT-NOT-FOUND (err u101))
(define-constant ERR-STUDENT-EXISTS (err u102))
(define-constant ERR-INVALID-DATE (err u103))
(define-constant ERR-ATTENDANCE-EXISTS (err u104))
(define-constant ERR-INVALID-STATUS (err u105))
(define-constant ERR-INVALID-STUDENT-ID (err u106))
(define-constant ERR-INVALID-INPUT (err u107))
(define-constant ERR-INVALID-TIME (err u108))

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)

;; Maximum values for validation
(define-constant MAX-STUDENT-ID u10000)
(define-constant MAX-DATE u999999999)
(define-constant MAX-TIME u86400)

;; Data structures
(define-map students
  { student-id: uint }
  {
    name: (string-ascii 50),
    email: (string-ascii 100),
    enrolled-date: uint,
    is-active: bool
  }
)

(define-map attendance-records
  { student-id: uint, date: uint }
  {
    status: (string-ascii 10),
    timestamp: uint,
    notes: (optional (string-ascii 200))
  }
)

(define-map class-sessions
  { date: uint }
  {
    session-name: (string-ascii 100),
    start-time: uint,
    end-time: uint,
    total-students: uint,
    present-count: uint
  }
)

;; Data variables
(define-data-var next-student-id uint u1)
(define-data-var total-students uint u0)

;; Authorization check
(define-private (is-authorized)
  (is-eq tx-sender CONTRACT-OWNER)
)

;; Enhanced validation functions
(define-private (is-valid-student-id (student-id uint))
  (and (> student-id u0) 
       (< student-id MAX-STUDENT-ID)
       (< student-id (var-get next-student-id)))
)

(define-private (is-valid-date (date uint))
  (and (> date u0) (< date MAX-DATE))
)

(define-private (is-valid-time (time uint))
  (< time MAX-TIME)
)

(define-private (is-valid-status (status (string-ascii 10)))
  (or (is-eq status "present") 
      (is-eq status "absent") 
      (is-eq status "late"))
)

(define-private (is-valid-name (name (string-ascii 50)))
  (and (> (len name) u0) (< (len name) u51))
)

(define-private (is-valid-email (email (string-ascii 100)))
  (and (> (len email) u5) (< (len email) u101))
)

(define-private (is-valid-session-name (session-name (string-ascii 100)))
  (and (> (len session-name) u0) (< (len session-name) u101))
)

(define-private (is-valid-notes (notes (optional (string-ascii 200))))
  (match notes
    note-text (< (len note-text) u201)
    true)
)

(define-private (student-exists (student-id uint))
  (is-some (map-get? students { student-id: student-id }))
)

;; Public functions

;; Add a new student with input validation
(define-public (add-student (name (string-ascii 50)) (email (string-ascii 100)))
  (let ((student-id (var-get next-student-id)))
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-name name) ERR-INVALID-INPUT)
    (asserts! (is-valid-email email) ERR-INVALID-INPUT)
    
    (map-set students
      { student-id: student-id }
      {
        name: name,
        email: email,
        enrolled-date: block-height,
        is-active: true
      }
    )
    
    (var-set next-student-id (+ student-id u1))
    (var-set total-students (+ (var-get total-students) u1))
    (ok student-id)
  )
)

;; Deactivate a student with proper validation
(define-public (deactivate-student (student-id uint))
  (begin
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-student-id student-id) ERR-INVALID-STUDENT-ID)
    
    (let ((student-data (unwrap! (map-get? students { student-id: student-id }) ERR-STUDENT-NOT-FOUND)))
      (asserts! (get is-active student-data) ERR-STUDENT-NOT-FOUND)
      
      (map-set students
        { student-id: student-id }
        (merge student-data { is-active: false })
      )
      (var-set total-students (- (var-get total-students) u1))
      (ok true)
    )
  )
)

;; Mark attendance with comprehensive validation
(define-public (mark-attendance (student-id uint) (date uint) (status (string-ascii 10)) (notes (optional (string-ascii 200))))
  (begin
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-student-id student-id) ERR-INVALID-STUDENT-ID)
    (asserts! (is-valid-date date) ERR-INVALID-DATE)
    (asserts! (is-valid-status status) ERR-INVALID-STATUS)
    (asserts! (is-valid-notes notes) ERR-INVALID-INPUT)
    
    (let ((student-data (unwrap! (map-get? students { student-id: student-id }) ERR-STUDENT-NOT-FOUND)))
      (asserts! (get is-active student-data) ERR-STUDENT-NOT-FOUND)
      (asserts! (is-none (map-get? attendance-records { student-id: student-id, date: date })) ERR-ATTENDANCE-EXISTS)
      
      (map-set attendance-records
        { student-id: student-id, date: date }
        {
          status: status,
          timestamp: block-height,
          notes: notes
        }
      )
      
      (update-class-session-stats date status)
      (ok true)
    )
  )
)

;; Update attendance record with validation
(define-public (update-attendance (student-id uint) (date uint) (status (string-ascii 10)) (notes (optional (string-ascii 200))))
  (begin
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-student-id student-id) ERR-INVALID-STUDENT-ID)
    (asserts! (is-valid-date date) ERR-INVALID-DATE)
    (asserts! (is-valid-status status) ERR-INVALID-STATUS)
    (asserts! (is-valid-notes notes) ERR-INVALID-INPUT)
    
    (let ((attendance-data (unwrap! (map-get? attendance-records { student-id: student-id, date: date }) ERR-STUDENT-NOT-FOUND)))
      (map-set attendance-records
        { student-id: student-id, date: date }
        {
          status: status,
          timestamp: block-height,
          notes: notes
        }
      )
      (ok true)
    )
  )
)

;; Create class session with input validation
(define-public (create-class-session (date uint) (session-name (string-ascii 100)) (start-time uint) (end-time uint))
  (begin
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-date date) ERR-INVALID-DATE)
    (asserts! (is-valid-session-name session-name) ERR-INVALID-INPUT)
    (asserts! (is-valid-time start-time) ERR-INVALID-TIME)
    (asserts! (is-valid-time end-time) ERR-INVALID-TIME)
    (asserts! (< start-time end-time) ERR-INVALID-TIME)
    
    (map-set class-sessions
      { date: date }
      {
        session-name: session-name,
        start-time: start-time,
        end-time: end-time,
        total-students: (var-get total-students),
        present-count: u0
      }
    )
    (ok true)
  )
)

;; Private function to update class session statistics
(define-private (update-class-session-stats (date uint) (status (string-ascii 10)))
  (let ((session-data (map-get? class-sessions { date: date })))
    (match session-data
      session-info
      (if (is-eq status "present")
        (map-set class-sessions
          { date: date }
          (merge session-info { present-count: (+ (get present-count session-info) u1) })
        )
        true
      )
      true
    )
  )
)

;; Read-only functions

;; Get student information with validation
(define-read-only (get-student (student-id uint))
  (if (is-valid-student-id student-id)
    (map-get? students { student-id: student-id })
    none
  )
)

;; Get attendance record with validation
(define-read-only (get-attendance (student-id uint) (date uint))
  (if (and (is-valid-student-id student-id) (is-valid-date date))
    (map-get? attendance-records { student-id: student-id, date: date })
    none
  )
)

;; Get class session information with validation
(define-read-only (get-class-session (date uint))
  (if (is-valid-date date)
    (map-get? class-sessions { date: date })
    none
  )
)

;; Get total number of students
(define-read-only (get-total-students)
  (var-get total-students)
)

;; Get next student ID
(define-read-only (get-next-student-id)
  (var-get next-student-id)
)

;; Calculate attendance percentage for a student
(define-read-only (get-student-attendance-rate (student-id uint) (total-classes uint))
  (if (and (is-valid-student-id student-id) (> total-classes u0))
    (match (map-get? students { student-id: student-id })
      student-data (ok (/ (* (count-student-present-days student-id) u100) total-classes))
      ERR-STUDENT-NOT-FOUND
    )
    ERR-INVALID-INPUT
  )
)

;; Helper function to count present days
(define-private (count-student-present-days (student-id uint))
  u0
)

;; Get contract owner
(define-read-only (get-contract-owner)
  CONTRACT-OWNER
)

;; Check if caller is authorized
(define-read-only (check-authorization)
  (is-authorized)
)

;; Batch mark attendance for multiple students
(define-public (batch-mark-attendance (student-ids (list 50 uint)) (date uint) (status (string-ascii 10)))
  (begin
    (asserts! (is-authorized) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-date date) ERR-INVALID-DATE)
    (asserts! (is-valid-status status) ERR-INVALID-STATUS)
    
    (ok (map mark-single-attendance-helper 
         (map create-attendance-tuple student-ids (list date) (list status))))
  )
)

;; Helper functions for batch operations
(define-private (create-attendance-tuple (student-id uint) (date uint) (status (string-ascii 10)))
  { student-id: student-id, date: date, status: status }
)

(define-private (mark-single-attendance-helper (attendance-data { student-id: uint, date: uint, status: (string-ascii 10) }))
  (let ((student-id (get student-id attendance-data))
        (date (get date attendance-data))
        (status (get status attendance-data)))
    (if (and (is-valid-student-id student-id) (student-exists student-id))
      (map-set attendance-records
        { student-id: student-id, date: date }
        {
          status: status,
          timestamp: block-height,
          notes: none
        }
      )
      false
    )
  )
)
