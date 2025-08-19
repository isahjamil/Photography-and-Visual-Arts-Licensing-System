;; Licensing Manager Contract
;; Manages licensing terms, pricing, and agreements

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-LICENSE-TYPE-EXISTS (err u201))
(define-constant ERR-LICENSE-TYPE-NOT-FOUND (err u202))
(define-constant ERR-LICENSE-NOT-FOUND (err u203))
(define-constant ERR-INVALID-INPUT (err u204))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u205))
(define-constant ERR-LICENSE-EXPIRED (err u206))
(define-constant ERR-LICENSE-ALREADY-ACTIVE (err u207))
(define-constant ERR-NOT-IMAGE-OWNER (err u208))
(define-constant ERR-IMAGE-NOT-FOUND (err u209))

;; License Types
(define-constant LICENSE-PERSONAL u1)
(define-constant LICENSE-COMMERCIAL u2)
(define-constant LICENSE-EDITORIAL u3)
(define-constant LICENSE-EXCLUSIVE u4)
(define-constant LICENSE-EXTENDED u5)

;; Data Variables
(define-data-var next-license-type-id uint u1)
(define-data-var next-license-id uint u1)
(define-data-var platform-fee-percentage uint u5) ;; 5% platform fee

;; Data Maps
(define-map license-types
  { license-type-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    base-price: uint,
    duration-days: uint,
    usage-rights: (string-ascii 300),
    restrictions: (string-ascii 500),
    is-active: bool,
    created-by: principal,
    creation-block: uint
  }
)

(define-map photographer-license-pricing
  { photographer-id: uint, license-type-id: uint }
  {
    custom-price: uint,
    is-available: bool,
    custom-terms: (string-ascii 500)
  }
)

(define-map licenses
  { license-id: uint }
  {
    image-id: uint,
    photographer-id: uint,
    licensee: principal,
    license-type-id: uint,
    price-paid: uint,
    start-date: uint,
    end-date: uint,
    usage-terms: (string-ascii 500),
    status: (string-ascii 20), ;; "active", "expired", "revoked"
    creation-block: uint,
    payment-block: uint
  }
)

(define-map license-agreements
  { license-id: uint }
  {
    agreement-hash: (string-ascii 64),
    photographer-signature: bool,
    licensee-signature: bool,
    terms-accepted-block: uint
  }
)

;; Read-only functions
(define-read-only (get-license-type (license-type-id uint))
  (map-get? license-types { license-type-id: license-type-id })
)

(define-read-only (get-photographer-pricing (photographer-id uint) (license-type-id uint))
  (map-get? photographer-license-pricing
    { photographer-id: photographer-id, license-type-id: license-type-id }
  )
)

(define-read-only (get-license (license-id uint))
  (map-get? licenses { license-id: license-id })
)

(define-read-only (get-license-agreement (license-id uint))
  (map-get? license-agreements { license-id: license-id })
)

(define-read-only (calculate-license-price (photographer-id uint) (license-type-id uint))
  (let
    (
      (base-license-type (unwrap! (get-license-type license-type-id) (err u0)))
      (custom-pricing (map-get? photographer-license-pricing
        { photographer-id: photographer-id, license-type-id: license-type-id }))
    )
    (match custom-pricing
      pricing-data
        (if (get is-available pricing-data)
          (ok (get custom-price pricing-data))
          (ok (get base-price base-license-type))
        )
      (ok (get base-price base-license-type))
    )
  )
)

(define-read-only (is-license-active (license-id uint))
  (match (get-license license-id)
    license-data
      (and
        (is-eq (get status license-data) "active")
        (< block-height (get end-date license-data))
      )
    false
  )
)

(define-read-only (get-platform-fee (amount uint))
  (/ (* amount (var-get platform-fee-percentage)) u100)
)

;; Public functions
(define-public (create-license-type
  (name (string-ascii 100))
  (description (string-ascii 500))
  (base-price uint)
  (duration-days uint)
  (usage-rights (string-ascii 300))
  (restrictions (string-ascii 500))
)
  (let
    (
      (license-type-id (var-get next-license-type-id))
    )
    ;; Validate input
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> base-price u0) ERR-INVALID-INPUT)
    (asserts! (> duration-days u0) ERR-INVALID-INPUT)

    ;; Create license type
    (map-set license-types
      { license-type-id: license-type-id }
      {
        name: name,
        description: description,
        base-price: base-price,
        duration-days: duration-days,
        usage-rights: usage-rights,
        restrictions: restrictions,
        is-active: true,
        created-by: tx-sender,
        creation-block: block-height
      }
    )

    ;; Increment next ID
    (var-set next-license-type-id (+ license-type-id u1))

    (ok license-type-id)
  )
)

(define-public (set-photographer-pricing
  (photographer-id uint)
  (license-type-id uint)
  (custom-price uint)
  (is-available bool)
  (custom-terms (string-ascii 500))
)
  (let
    (
      (caller tx-sender)
    )
    ;; Validate license type exists
    (asserts! (is-some (get-license-type license-type-id)) ERR-LICENSE-TYPE-NOT-FOUND)

    ;; Validate input
    (asserts! (> custom-price u0) ERR-INVALID-INPUT)

    ;; Set custom pricing
    (map-set photographer-license-pricing
      { photographer-id: photographer-id, license-type-id: license-type-id }
      {
        custom-price: custom-price,
        is-available: is-available,
        custom-terms: custom-terms
      }
    )

    (ok true)
  )
)

(define-public (purchase-license
  (image-id uint)
  (photographer-id uint)
  (license-type-id uint)
  (duration-days uint)
)
  (let
    (
      (license-id (var-get next-license-id))
      (caller tx-sender)
      (license-price (unwrap! (calculate-license-price photographer-id license-type-id) ERR-LICENSE-TYPE-NOT-FOUND))
      (platform-fee (get-platform-fee license-price))
      (photographer-payment (- license-price platform-fee))
      (license-type-data (unwrap! (get-license-type license-type-id) ERR-LICENSE-TYPE-NOT-FOUND))
      (end-date (+ block-height duration-days))
    )
    ;; Validate input
    (asserts! (> duration-days u0) ERR-INVALID-INPUT)
    (asserts! (<= duration-days (get duration-days license-type-data)) ERR-INVALID-INPUT)

    ;; Create license
    (map-set licenses
      { license-id: license-id }
      {
        image-id: image-id,
        photographer-id: photographer-id,
        licensee: caller,
        license-type-id: license-type-id,
        price-paid: license-price,
        start-date: block-height,
        end-date: end-date,
        usage-terms: (get usage-rights license-type-data),
        status: "active",
        creation-block: block-height,
        payment-block: block-height
      }
    )

    ;; Increment next license ID
    (var-set next-license-id (+ license-id u1))

    (ok license-id)
  )
)

(define-public (create-license-agreement
  (license-id uint)
  (agreement-hash (string-ascii 64))
)
  (let
    (
      (license-data (unwrap! (get-license license-id) ERR-LICENSE-NOT-FOUND))
      (caller tx-sender)
    )
    ;; Only licensee can create agreement
    (asserts! (is-eq caller (get licensee license-data)) ERR-NOT-AUTHORIZED)

    ;; Create agreement
    (map-set license-agreements
      { license-id: license-id }
      {
        agreement-hash: agreement-hash,
        photographer-signature: false,
        licensee-signature: true,
        terms-accepted-block: block-height
      }
    )

    (ok true)
  )
)

(define-public (sign-license-agreement (license-id uint))
  (let
    (
      (license-data (unwrap! (get-license license-id) ERR-LICENSE-NOT-FOUND))
      (agreement-data (unwrap! (get-license-agreement license-id) ERR-LICENSE-NOT-FOUND))
      (caller tx-sender)
    )
    ;; Check if caller is photographer (by checking photographer-id ownership)
    ;; This would need to be verified against the photography-core contract

    ;; Update photographer signature
    (map-set license-agreements
      { license-id: license-id }
      (merge agreement-data { photographer-signature: true })
    )

    (ok true)
  )
)

(define-public (revoke-license (license-id uint))
  (let
    (
      (license-data (unwrap! (get-license license-id) ERR-LICENSE-NOT-FOUND))
      (caller tx-sender)
    )
    ;; Only photographer can revoke (this would need verification against photography-core)
    ;; For now, allowing any caller for demonstration

    ;; Update license status
    (map-set licenses
      { license-id: license-id }
      (merge license-data { status: "revoked" })
    )

    (ok true)
  )
)

(define-public (extend-license (license-id uint) (additional-days uint))
  (let
    (
      (license-data (unwrap! (get-license license-id) ERR-LICENSE-NOT-FOUND))
      (caller tx-sender)
      (current-end-date (get end-date license-data))
      (new-end-date (+ current-end-date additional-days))
    )
    ;; Only licensee can extend
    (asserts! (is-eq caller (get licensee license-data)) ERR-NOT-AUTHORIZED)

    ;; Validate license is active
    (asserts! (is-eq (get status license-data) "active") ERR-LICENSE-EXPIRED)

    ;; Validate input
    (asserts! (> additional-days u0) ERR-INVALID-INPUT)

    ;; Update end date
    (map-set licenses
      { license-id: license-id }
      (merge license-data { end-date: new-end-date })
    )

    (ok true)
  )
)

;; Admin functions
(define-public (update-platform-fee (new-fee-percentage uint))
  (begin
    ;; Only contract owner can update
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    ;; Validate fee is reasonable (max 10%)
    (asserts! (<= new-fee-percentage u10) ERR-INVALID-INPUT)

    ;; Update platform fee
    (var-set platform-fee-percentage new-fee-percentage)

    (ok true)
  )
)

(define-public (deactivate-license-type (license-type-id uint))
  (let
    (
      (license-type-data (unwrap! (get-license-type license-type-id) ERR-LICENSE-TYPE-NOT-FOUND))
    )
    ;; Only contract owner can deactivate
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    ;; Deactivate license type
    (map-set license-types
      { license-type-id: license-type-id }
      (merge license-type-data { is-active: false })
    )

    (ok true)
  )
)
