package backend

import "fmt"

// Input is an end-of-day till count. Only CASH flows feed the reconciliation;
// UPI/card sales are captured separately so near-universal digital payment
// doesn't fake a shortage.
type Input struct {
	OpeningCash   float64 `json:"openingCash"`
	CashSales     float64 `json:"cashSales"`   // cash-tender sales only
	UPISales      float64 `json:"upiSales"`    // informational, not reconciled against the till
	CardSales     float64 `json:"cardSales"`   // informational
	Expenses      float64 `json:"expenses"`    // cash paid out for expenses
	Payouts       float64 `json:"payouts"`     // owner drawings / supplier cash
	CountedClosing float64 `json:"countedClosing"` // physically counted cash in the till
}

// Result is the reconciliation outcome.
type Result struct {
	ExpectedCash float64 `json:"expectedCash"`
	Gap          float64 `json:"gap"` // counted - expected (negative = short)
	Status       string  `json:"status"`
}

// Headline is the till gap.
func (r Result) Headline() float64 { return r.Gap }

// Label is the reconciliation status.
func (r Result) Label() string { return r.Status }

// Validate reports whether the Input is well formed.
func (in Input) Validate() error {
	if in.OpeningCash < 0 || in.CashSales < 0 || in.Expenses < 0 || in.Payouts < 0 || in.CountedClosing < 0 {
		return fmt.Errorf("cash amounts cannot be negative")
	}
	return nil
}

// Evaluate computes expected cash from cash-only flows and the gap vs the count.
func Evaluate(in Input) Result {
	expected := in.OpeningCash + in.CashSales - in.Expenses - in.Payouts
	gap := in.CountedClosing - expected
	status := "exact"
	if gap < -1e-9 {
		status = "short"
	} else if gap > 1e-9 {
		status = "over"
	}
	return Result{ExpectedCash: expected, Gap: gap, Status: status}
}
