;; BitStack - Bitcoin-Backed Lending Protocol
;; A DeFi lending platform built on Stacks

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u2))
(define-constant ERR-LOAN-NOT-FOUND (err u3))
(define-constant ERR-LOAN-ALREADY-ACTIVE (err u4))
(define-constant COLLATERAL-RATIO u150) ;; 150% collateralization ratio

;; Data vars
(define-data-var minimum-collateral uint u100000) ;; in sats
(define-data-var protocol-fee uint u100) ;; basis points (1% = 100)
(define-data-var last-loan-id uint u0)

;; Data maps
(define-map loans
    { loan-id: uint }
    {
        borrower: principal,
        lender: principal,
        amount: uint,
        collateral: uint,
        interest-rate: uint,
        start-height: uint,
        end-height: uint,
        status: (string-ascii 20)
    }
)

(define-map user-loans
    principal
    (list 10 uint)
)

;; Public functions
(define-public (create-loan (amount uint) (collateral uint) (interest-rate uint) (loan-duration uint))
    (let
        (
            (caller tx-sender)
            (loan-id (get-next-loan-id))
        )
        ;; Validate collateral ratio
        (asserts! (is-collateral-ratio-valid amount collateral) ERR-INSUFFICIENT-COLLATERAL)
        
        ;; Create loan entry
        (map-set loans 
            { loan-id: loan-id }
            {
                borrower: caller,
                lender: caller,
                amount: amount,
                collateral: collateral,
                interest-rate: interest-rate,
                start-height: block-height,
                end-height: (+ block-height loan-duration),
                status: "PENDING"
            }
        )
        
        ;; Update user's loan list
        (map-set user-loans
            caller
            (unwrap! 
                (as-max-len? 
                    (append 
                        (default-to (list) (map-get? user-loans caller)) 
                        loan-id
                    ) 
                    u10
                )
                ERR-NOT-AUTHORIZED
            )
        )
        
        (ok loan-id)
    )
)

(define-public (fund-loan (loan-id uint))
    (let
        (
            (loan (unwrap! (map-get? loans { loan-id: loan-id }) ERR-LOAN-NOT-FOUND))
            (caller tx-sender)
        )
        (asserts! (is-eq (get status loan) "PENDING") ERR-LOAN-ALREADY-ACTIVE)
        (asserts! (not (is-eq (get borrower loan) caller)) ERR-NOT-AUTHORIZED)
        
        ;; Update loan status and set lender
        (map-set loans
            { loan-id: loan-id }
            (merge loan {
                lender: caller,
                status: "ACTIVE"
            })
        )
        
        (ok true)
    )
)

(define-public (repay-loan (loan-id uint))
    (let
        (
            (loan (unwrap! (map-get? loans { loan-id: loan-id }) ERR-LOAN-NOT-FOUND))
            (caller tx-sender)
        )
        (asserts! (is-eq (get borrower loan) caller) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get status loan) "ACTIVE") ERR-LOAN-NOT-FOUND)
        
        ;; Calculate repayment amount with interest
        (let
            (
                (interest-amount (calculate-interest
                    (get amount loan)
                    (get interest-rate loan)
                    (- block-height (get start-height loan))
                ))
                (total-repayment (+ (get amount loan) interest-amount))
            )
            
            ;; Update loan status
            (map-set loans
                { loan-id: loan-id }
                (merge loan {
                    status: "REPAID"
                })
            )
            
            (ok true)
        )
    )
)

;; Private functions
(define-private (is-collateral-ratio-valid (loan-amount uint) (collateral-amount uint))
    (let
        (
            (min-collateral (* loan-amount COLLATERAL-RATIO))
        )
        (>= (* collateral-amount u10000) min-collateral)
    )
)

(define-private (calculate-interest (principal uint) (rate uint) (blocks uint))
    (let
        (
            (interest-per-block (/ (* principal rate) (* u10000 u144))) ;; Assuming 144 blocks per day
        )
        (* interest-per-block blocks)
    )
)

(define-private (get-next-loan-id)
    (let
        (
            (current-id (var-get last-loan-id))
            (next-id (+ current-id u1))
        )
        (var-set last-loan-id next-id)
        next-id
    )
)

;; Read-only functions
(define-read-only (get-loan (loan-id uint))
    (map-get? loans { loan-id: loan-id })
)

(define-read-only (get-user-loans (user principal))
    (default-to (list) (map-get? user-loans user))
)