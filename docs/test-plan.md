# Campus Delivery — Manual Test Plan

## Purpose
Verify that customers and couriers can complete the campus delivery workflow correctly.

## Test Environment
- Application: Campus Delivery
- Roles: Customer and Courier
- Testing method: Manual functional testing
- Result options: Pass / Fail / Not Tested

## Manual Test Cases

| ID | Test Scenario | Expected Result | Status |
|---|---|---|---|
| D-07 | Customer creates a delivery request | New order appears in the courier's Available Requests list | Not Tested |
| D-08 | Courier accepts an available order | Customer sees the order status change to Accepted | Not Tested |
| D-09 | Courier picks up and delivers an order | Order changes to Delivered and courier earnings increase correctly | Not Tested |
| D-10 | Two couriers attempt to accept the same order | Only one courier successfully accepts; the other receives an appropriate error | Not Tested |
| MT-01 | Customer submits an incomplete order | Application prevents invalid submission | Not Tested |
| MT-02 | Courier opens Available Requests with no pending orders | Application displays an appropriate empty state | Not Tested |
| MT-03 | Customer checks an active order | Current delivery status is displayed correctly | Not Tested |
| MT-04 | Application encounters a network error | Application displays an error without crashing | Not Tested |

## Testing Procedure
1. Start the application and backend services.
2. Sign in or enter demo mode as a customer.
3. Create a delivery request using valid pickup and drop-off locations.
4. Open the courier view and verify the request appears.
5. Accept the request and verify the customer-facing status.
6. Update the order to Picked Up and then Delivered.
7. Confirm the courier's earnings reflect the completed delivery.
8. Repeat with two couriers attempting to accept the same request.
9. Record actual results and any defects.

## Defect Reporting
For failed tests, record:
- Test case ID
- Steps to reproduce
- Expected behavior
- Actual behavior
- Screenshot or error message
- Severity and resolution status

## Completion Criteria
All required D-07 through D-10 scenarios must pass before the delivery workflow is considered verified.
