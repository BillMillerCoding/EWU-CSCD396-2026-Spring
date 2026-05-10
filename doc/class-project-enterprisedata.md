# Overview
Scenario informed by real world projects we've done with customers, but simplified to be achievable in a class project. The goal is to demonstrate using Azure services together to build a solution.

## Business Problem
- Gather data from devices in the field
- Process the data into useful information
- Provide a web front end to view aggregated data and related information
- Provide an API to return data: specific points, metadata, aggregated results
- Provide a site to manage and organize metadata and devices
- Orders are taken for fictional service and are fulfilled by devices in the field, so we need to be able to track orders and fulfillment status
- Determine the best device for an order based on location, availability, and other factors

### Assumptions
- 1000s of devices in the field generating high volume data
- Wide interest in the aggregated results
- Solution must be scalable, globally available, cost effective
- Data must be stored durably, but also accessible for processing and querying
- Data must be processed in near real time to be useful (what's happenging now or today)
- Longer term data aggregations do not need to be real time (What does this week look like, how are we doing month over month, quarter over quarter, etc)

### Data Model
Device
- Each device has a set of metadata associated with it (location, type, etc)
- Each device has a unique identifier that is used to associate it with the data it generates
- Device configuration is retrieved from an api endpoint
- Devices belong to a device group

Device Group
- Group of devices

Orders
- Orders placed by customers delivered to a device

Order Fulfillment
- Completion of an order on a device

Customer
- Customers place orders that are fulfilled by devices in the field
- Customers have a unique identifier and associated metadata (location, preferences, etc)

## Solution Components and Services


## Ideas and Stretches

- Devices occasionally disconnect and reconnect, so we need to be able to handle that gracefully
- We want to be able to send notifications or alerts based on certain conditions in the data (e.g. if a certain threshold is exceeded, or if we see a certain pattern in the data)


## Action Items
- Pick one:
  - Either a device that "moves": tracking location and doing location matching: Autonomous vehicles, delivery robots
  - or a devices that gathers data and may need to be serviced: temperature sensors, air quality monitors, etc
  - Autonomous cleaning robots (like in Central Park?)
  - ATM ?
  - Bitcoin ATMs?
  