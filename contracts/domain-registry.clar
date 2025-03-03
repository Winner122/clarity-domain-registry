;; Domain Registry Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-registered (err u101))
(define-constant err-not-domain-owner (err u102))
(define-constant err-expired (err u103))
(define-constant err-invalid-subdomain (err u104))
(define-constant err-invalid-format (err u105))
(define-constant err-name-too-long (err u106))
(define-constant err-empty-name (err u107))
(define-constant err-consecutive-hyphens (err u108))
(define-constant registration-duration u31536000) ;; 1 year in seconds
(define-constant valid-domain-regex "^[a-z0-9]+[a-z0-9-]*[a-z0-9]+\.btc$")
(define-constant max-name-length u64)
(define-constant max-subdomain-length u32)

;; Data vars
(define-map domains
    principal
    {
        name: (string-ascii 64),
        owner: principal,
        expires: uint,
        subdomains: (list 20 (string-ascii 64))
    }
)

(define-map name-to-address
    (string-ascii 64)
    principal
)

;; Events
(define-data-var last-event-id uint u0)

(define-private (emit-domain-event (event-type (string-ascii 12)) (domain (string-ascii 64)) (owner principal))
    (begin
        (var-set last-event-id (+ (var-get last-event-id) u1))
        (print { 
            event-id: (var-get last-event-id), 
            type: event-type, 
            domain: domain,
            owner: owner,
            timestamp: (unwrap-panic (get-block-info? time u0))
        })
    )
)

;; Private functions
(define-private (normalize-name (name (string-ascii 64)))
    (to-lower name)
)

(define-private (has-consecutive-hyphens (name (string-ascii 64)))
    (match (string-find? "--" name)
        success true
        false
    )
)

(define-private (is-valid-format (name (string-ascii 64)))
    (and
        (> (len name) u0)
        (<= (len name) max-name-length)
        (not (has-consecutive-hyphens name))
        (match (string-matches? valid-domain-regex name)
            success true
            false)
    )
)

(define-private (is-valid-subdomain (domain-name (string-ascii 64)) (subdomain (string-ascii 64)))
    (let (
        (domain-parts (as-max-len? (string-split domain-name ".") u3))
    )
    (and
        (is-some domain-parts)
        (<= (len (unwrap-panic domain-parts)) u2)
        (> (len subdomain) u0)
        (<= (len subdomain) max-subdomain-length)
        (is-valid-format subdomain)
        (not (has-consecutive-hyphens subdomain))
    ))
)

;; Public functions
(define-public (register-domain (name (string-ascii 64)))
    (let (
        (normalized-name (normalize-name name))
        (existing-registration (map-get? name-to-address normalized-name))
        (block-time (unwrap-panic (get-block-info? time u0)))
        (expiry (+ block-time registration-duration))
    )
    (asserts! (> (len normalized-name) u0) err-empty-name)
    (asserts! (is-valid-format normalized-name) err-invalid-format)
    (asserts! (is-none existing-registration) err-already-registered)
    (map-set domains tx-sender {
        name: normalized-name,
        owner: tx-sender,
        expires: expiry,
        subdomains: (list)
    })
    (map-set name-to-address normalized-name tx-sender)
    (emit-domain-event "register" normalized-name tx-sender)
    (ok true))
)

[... rest of the contract remains the same ...]
