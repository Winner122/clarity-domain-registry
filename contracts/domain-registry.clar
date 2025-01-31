;; Domain Registry Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-registered (err u101))
(define-constant err-not-domain-owner (err u102))
(define-constant err-expired (err u103))
(define-constant registration-duration u31536000) ;; 1 year in seconds

;; Data vars
(define-map domains
    principal
    {
        name: (string-ascii 64),
        owner: principal,
        expires: uint
    }
)

(define-map name-to-address
    (string-ascii 64)
    principal
)

;; Public functions
(define-public (register-domain (name (string-ascii 64)))
    (let (
        (existing-registration (map-get? name-to-address name))
        (block-time (unwrap-panic (get-block-info? time u0)))
        (expiry (+ block-time registration-duration))
    )
    (asserts! (is-none existing-registration) err-already-registered)
    (map-set domains tx-sender {
        name: name,
        owner: tx-sender,
        expires: expiry
    })
    (map-set name-to-address name tx-sender)
    (ok true))
)

(define-public (transfer-domain (new-owner principal))
    (let (
        (domain (unwrap! (map-get? domains tx-sender) err-not-domain-owner))
        (block-time (unwrap-panic (get-block-info? time u0)))
    )
    (asserts! (< block-time (get expires domain)) err-expired)
    (map-set domains new-owner domain)
    (map-set name-to-address (get name domain) new-owner)
    (map-delete domains tx-sender)
    (ok true))
)

(define-public (renew-domain)
    (let (
        (domain (unwrap! (map-get? domains tx-sender) err-not-domain-owner))
        (block-time (unwrap-panic (get-block-info? time u0)))
        (new-expiry (+ block-time registration-duration))
    )
    (map-set domains tx-sender
        (merge domain { expires: new-expiry })
    )
    (ok true))
)

;; Read only functions
(define-read-only (get-domain-owner (name (string-ascii 64)))
    (map-get? name-to-address name)
)

(define-read-only (get-domain-info (owner principal))
    (map-get? domains owner)
)

(define-read-only (is-domain-available (name (string-ascii 64)))
    (is-none (map-get? name-to-address name))
)
