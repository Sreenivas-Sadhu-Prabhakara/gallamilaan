package backend

import (
	"encoding/json"
	"math"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func almost(a, b float64) bool { return math.Abs(a-b) < 1e-6 }

func TestEvaluate_ShortTill(t *testing.T) {
	// opening 2000 + cash sales 5000 - expenses 300 - payouts 500 = 6200 expected.
	// counted 6100 => 100 short. UPI/card must NOT affect it.
	r := Evaluate(Input{OpeningCash: 2000, CashSales: 5000, UPISales: 9000, CardSales: 1000,
		Expenses: 300, Payouts: 500, CountedClosing: 6100})
	if !almost(r.ExpectedCash, 6200) {
		t.Fatalf("expected=%v want 6200", r.ExpectedCash)
	}
	if !almost(r.Gap, -100) || r.Status != "short" {
		t.Fatalf("gap=%v status=%s want -100/short", r.Gap, r.Status)
	}
}

func TestEvaluate_Exact(t *testing.T) {
	r := Evaluate(Input{OpeningCash: 1000, CashSales: 1000, CountedClosing: 2000})
	if r.Status != "exact" {
		t.Fatalf("status=%s want exact", r.Status)
	}
}

func TestValidate(t *testing.T) {
	if err := (Input{OpeningCash: 100}).Validate(); err != nil {
		t.Fatalf("valid rejected: %v", err)
	}
	if err := (Input{OpeningCash: -1}).Validate(); err == nil {
		t.Fatal("negative accepted")
	}
}

func TestEvaluateEndpoint(t *testing.T) {
	srv := NewServer(nil)
	body := `{"openingCash":2000,"cashSales":5000,"expenses":300,"payouts":500,"countedClosing":6100}`
	rec := httptest.NewRecorder()
	srv.ServeHTTP(rec, httptest.NewRequest(http.MethodPost, "/evaluate", strings.NewReader(body)))
	if rec.Code != http.StatusOK {
		t.Fatalf("status %d", rec.Code)
	}
	var r Result
	json.Unmarshal(rec.Body.Bytes(), &r)
	if r.Status != "short" {
		t.Fatalf("status=%s want short", r.Status)
	}
}
