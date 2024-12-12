;; BitStack - Bitcoin-Backed Lending Protocol
;; A DeFi lending platform built on Stacks

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u2))
(define-constant ERR-LOAN-NOT-FOUND (err u3))
(define-constant ERR-LOAN-ALREADY-ACTIVE (err u4))
(define-constant ERR-INVALID-INPUT (err u5))
(define-constant ERR-INSUFFICIENT-EXCESS-COLLATERAL (err u6))
(define-constant COLLATERAL-RATIO u150) ;; 150% collateralization ratio
(define-constant MAX-LOAN-DURATION u2880) ;; ~20 days (144 blocks/day)
(define-constant MAX-INTEREST-RATE u1000) ;; 10% max interest rate
(define-constant MIN-COLLATERAL-BUFFER u50) ;; Minimum buffer to prevent withdrawals that could liquidate the loan

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

;; Input validation functions
(define-private (is-valid-input 
    (amount uint) 
    (collateral uint) 
    (interest-rate uint) 
    (loan-duration uint)
)
    (and
        ;; Amount and collateral must be positive
        (> amount u0)
        (> collateral u0)
        
        ;; Interest rate within bounds
        (<= interest-rate MAX-INTEREST-RATE)
        
        ;; Loan duration within reasonable limits
        (and (> loan-duration u0) (<= loan-duration MAX-LOAN-DURATION))
        
        ;; Validate collateral ratio
        (is-collateral-ratio-valid amount collateral)
    )
)

;; Collateral management functions
(define-private (calculate-minimum-required-collateral (loan-amount uint))
    (/ (* loan-amount COLLATERAL-RATIO) u10000)
)

(define-private (calculate-max-withdrawable-collateral 
    (current-collateral uint) 
    (loan-amount uint)
)
    (let
        (
            (min-required (calculate-minimum-required-collateral loan-amount))
            ;; Add a small buffer to prevent risky withdrawals
            (safe-buffer (/ min-required u10))
        )
        (if (> current-collateral (+ min-required safe-buffer))
            (- current-collateral (+ min-required safe-buffer))
            u0
        )
    )
)

;; Public functions
(define-public (withdraw-excess-collateral 
    (loan-id uint) 
    (withdrawal-amount uint)
)
    (let
        (
            (loan (unwrap! (map-get? loans { loan-id: loan-id }) ERR-LOAN-NOT-FOUND))
            (caller tx-sender)
        )
        ;; Validate inputs
        (asserts! (is-eq (get borrower loan) caller) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get status loan) "ACTIVE") ERR-LOAN-NOT-FOUND)
        
        ;; Calculate maximum withdrawable amount
        (let
            (
                (max-withdrawable 
                    (calculate-max-withdrawable-collateral 
                        (get collateral loan) 
                        (get amount loan)
                    )
                )
            )
            ;; Ensure withdrawal amount is valid
            (asserts! (> withdrawal-amount u0) ERR-INVALID-INPUT)
            (asserts! (<= withdrawal-amount max-withdrawable) ERR-INSUFFICIENT-EXCESS-COLLATERAL)
            
            ;; Update loan with reduced collateral
            (map-set loans
                { loan-id: loan-id }
                (merge loan {
                    collateral: (- (get collateral loan) withdrawal-amount)
                })
            )
            
            ;; Transfer collateral back to borrower (placeholder - actual transfer mechanism depends on implementation)
            (ok withdrawal-amount)
        )
    )
)

;; Public functions
(define-public (create-loan 
    (amount uint) 
    (collateral uint) 
    (interest-rate uint) 
    (loan-duration uint)
)
    (let
        (
            (caller tx-sender)
            (loan-id (get-next-loan-id))
        )
        ;; Validate all inputs
        (asserts! 
            (is-valid-input amount collateral interest-rate loan-duration) 
            ERR-INVALID-INPUT
        )
        
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
        ;; Additional validation for loan-id
        (asserts! (> loan-id u0) ERR-INVALID-INPUT)
        
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
        ;; Additional validation for loan-id
        (asserts! (> loan-id u0) ERR-INVALID-INPUT)
        
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