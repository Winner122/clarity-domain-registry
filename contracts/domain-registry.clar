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

(define-private (emit-domain-event (event-type (string-ascii 12)) (domain (string-ascii 64)))
    (begin
        (var-set last-event-id (+ (var-get last-event-id) u1))
        (print { event-id: (var-get last-event-id), type: event-type, domain: domain })
    )
)

;; Private functions
(define-private (is-valid-format (name (string-ascii 64)))
    (and
        (<= (len name) max-name-length)
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
        (<= (len subdomain) max-subdomain-length)
        (is-valid-format subdomain)
    ))
)

;; Public functions
(define-public (register-domain (name (string-ascii 64)))
    (let (
        (existing-registration (map-get? name-to-address name))
        (block-time (unwrap-panic (get-block-info? time u0)))
        (expiry (+ block-time registration-duration))
    )
    (asserts! (is-valid-format name) err-invalid-format)
    (asserts! (is-none existing-registration) err-already-registered)
    (map-set domains tx-sender {
        name: name,
        owner: tx-sender,
        expires: expiry,
        subdomains: (list)
    })
    (map-set name-to-address name tx-sender)
    (emit-domain-event "register" name)
    (ok true))
)

(define-public (register-subdomain (domain-name (string-ascii 64)) (subdomain (string-ascii 64)))
    (let (
        (domain-owner (unwrap! (map-get? name-to-address domain-name) err-not-domain-owner))
        (domain (unwrap! (map-get? domains domain-owner) err-not-domain-owner))
        (block-time (unwrap-panic (get-block-info? time u0)))
        (full-subdomain (concat (concat subdomain ".") domain-name))
    )
    (asserts! (is-eq tx-sender domain-owner) err-not-domain-owner)
    (asserts! (< block-time (get expires domain)) err-expired)
    (asserts! (is-valid-subdomain domain-name subdomain) err-invalid-subdomain)
    (asserts! (is-none (map-get? name-to-address full-subdomain)) err-already-registered)
    
    ;; Update domain owner's subdomain list
    (map-set domains domain-owner 
        (merge domain 
            { subdomains: (unwrap-panic (as-max-len? 
                (append (get subdomains domain) full-subdomain) 
                u20))}))
    
    ;; Create separate record for subdomain
    (map-set domains tx-sender {
        name: full-subdomain,
        owner: tx-sender,
        expires: (get expires domain),
        subdomains: (list)
    })
    (map-set name-to-address full-subdomain tx-sender)
    (emit-domain-event "subdomain" full-subdomain)
    (ok true))
)
