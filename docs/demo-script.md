# Campus Delivery — Demo Script

**Project:** Campus Delivery  
**Purpose:** Demonstrate the customer-to-courier delivery workflow.

## 1. Introduction
"Hello! Today we're demonstrating Campus Delivery, an application designed to connect customers requesting deliveries with available campus couriers."

## 2. Customer Creates an Order (D-07)
"First, we'll enter the customer view and create a delivery request. We'll select a pickup location, a drop-off location, and submit the order."

Show the newly created order appearing in the courier's Available Requests list.

## 3. Courier Accepts an Order (D-08)
"Next, a courier can view available delivery requests and accept an order. Once accepted, the customer's order status should update to reflect that a courier has been assigned."

Show the accepted status in the customer view.

## 4. Courier Completes Delivery (D-09)
"After collecting the order, the courier updates the status to Picked Up. Once the delivery is completed, the status changes to Delivered."

Show the courier earnings balance before and after delivery.

## 5. Preventing Duplicate Acceptance (D-10)
"The application also needs to prevent multiple couriers from accepting the same order. We'll demonstrate that once one courier accepts a request, a second courier cannot claim it."

Show the second acceptance attempt being rejected.

## 6. Automated Testing
"Our GitHub Actions workflow checks Flutter code analysis, runs automated tests, and builds the Flutter web application to help catch issues before changes are merged."

Show the GitHub Actions workflow results.

## 7. Conclusion
"That concludes our demonstration of the Campus Delivery workflow, including order creation, courier acceptance, delivery completion, and duplicate acceptance protection."
