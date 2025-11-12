// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using System.TestTools.CodeCoverage;
using System.TestLibraries.Utilities;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Manufacturing.Routing;
using System.Tooling;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Document;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Journal;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Inventory;
using Microsoft.Manufacturing.Setup;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Requisition;

codeunit 137082 "SCM Manufacturing - Routings"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM] [Production] [Routing]
    end;

    var
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
        LibraryCalcComplexity: Codeunit "Library - Calc. Complexity";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        NotLinearCCErr: Label 'Computational cost is not linear.';
        CircularReferenceErr: Label 'Circular reference in routing %1', Comment = '%1 = Routing No.';
        WrongNoOfTerminationProcessesErr: Label 'Actual number of termination processes in route %1 is %2', Comment = '%1 = Routing No., %2 = No. of operations';
        WrongNoOfStartProcessesErr: Label 'Actual number of start processes in route %1 is %2', Comment = '%1 = Routing No., %2 = No. of operations';
        NoLineWithinFilterErr: Label 'There is no Routing Line within the filter';
        ItemTrackingMode: Option SetLotNo,VerifyTotals;
        isInitialized: Boolean;
        CannotDeleteWorkMachineCenterErr: Label 'You cannot delete %1 %2 because there is at least one %3 associated with it.';
        WorkMachineCenterNotExistErr: Label 'Operation no. %1 uses %2 no. %3 that no longer exists.', Comment = '%1 - Routing Line Operation No.; %2 - Work Center or Machine Center table caption; %3 - Work or Machine Center No.';
        ActionMustBeDisabledErr: Label 'Action must be disabled';
        ActionMustBeEnabledErr: Label 'Action must be enabled';
        StartingDateTimeMustBeLessErr: Label 'Starting Date-Time of 1st Prod. Order Routing line must be less than Satrting Date-Time of 2nd Prod. Order Routing Line.';

    [Test]
    [Scope('OnPrem')]
    procedure SimpleSerialRouting()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[3] of Record "Routing Line";
        I: Integer;
    begin
        // [FEATURE] [Serial Routing]
        // [SCENARIO 221561] Certification of a serial routing should update sequence numbers on routing operations

        Initialize();

        // [GIVEN] Create a serial routing with 3 operations
        // [GIVEN] 1 -> 2 -> 3
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        for I := 1 to ArrayLen(RoutingLine) do
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[I], '', Format(I), RoutingLine[I].Type::"Work Center", WorkCenter."No.");

        // [WHEN] Certify the routing
        CertifyRoutingAndRefreshLines(RoutingHeader, RoutingLine);

        // [THEN] The field "Sequence No. (Forward)" in operations has numbers from 1 to 3
        // [THEN] The field "Sequence No. (Backeward)" in operations has numbers from 3 to 1
        for I := 1 to ArrayLen(RoutingLine) do begin
            RoutingLine[I].Find();
            RoutingLine[I].TestField("Sequence No. (Forward)", I);
            RoutingLine[I].TestField("Sequence No. (Backward)", ArrayLen(RoutingLine) - I + 1);
        end;

        // [THEN] "Previous Operation No." is blank in the starting operation
        // [THEN] "Next Operation No." is blank in the terminal operation
        RoutingLine[1].TestField("Next Operation No.", RoutingLine[2]."Operation No.");
        RoutingLine[1].TestField("Previous Operation No.", '');

        RoutingLine[2].TestField("Next Operation No.", RoutingLine[3]."Operation No.");
        RoutingLine[2].TestField("Previous Operation No.", RoutingLine[1]."Operation No.");

        RoutingLine[3].TestField("Next Operation No.", '');
        RoutingLine[3].TestField("Previous Operation No.", RoutingLine[2]."Operation No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SimpleParallelRouting()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[3] of Record "Routing Line";
        I: Integer;
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO 221561] Certification of a parallel routing should update sequence numbers on routing operations

        Initialize();

        // [GIVEN] Create a parallel routing with 3 operations
        // [GIVEN] 1 -> 2 -> 3
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        for I := 1 to ArrayLen(RoutingLine) do
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[I], '', Format(I), RoutingLine[I].Type::"Work Center", WorkCenter."No.");

        // [GIVEN] Setup sequential execuion of the operations by filling the "Next Operation No." field
        SetNextOperationNo(RoutingLine[1], RoutingLine[2]."Operation No.");
        SetNextOperationNo(RoutingLine[2], RoutingLine[3]."Operation No.");

        // [WHEN] Certify the routing
        CertifyRoutingAndRefreshLines(RoutingHeader, RoutingLine);

        // [THEN] The field "Sequence No. (Forward)" in operations has numbers from 1 to 3
        // [THEN] The field "Sequence No. (Backeward)" in operations has numbers from 3 to 1
        for I := 1 to ArrayLen(RoutingLine) do begin
            RoutingLine[I].Find();
            RoutingLine[I].TestField("Sequence No. (Forward)", I);
            RoutingLine[I].TestField("Sequence No. (Backward)", ArrayLen(RoutingLine) - I + 1);
        end;

        // [THEN] "Previous Operation No." is blank in the starting operation
        // [THEN] "Next Operation No." is blank in the terminal operation
        RoutingLine[1].TestField("Previous Operation No.", '');
        RoutingLine[2].TestField("Previous Operation No.", RoutingLine[1]."Operation No.");
        RoutingLine[3].TestField("Previous Operation No.", RoutingLine[2]."Operation No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertifyRoutingTwoParallelOperations()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[4] of Record "Routing Line";
        I: Integer;
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO 221561] Two parallel operations should receive the same sequence no. on certifying a routing

        Initialize();

        // [GIVEN] Create a parallel routing with 4 operations
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        for I := 1 to ArrayLen(RoutingLine) do
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[I], '', Format(I), RoutingLine[I].Type::"Work Center", WorkCenter."No.");

        // [GIVEN] Setup the execution path: starting operation 1, operations 2 and 3 are executed in parallel, terminal operation 4
        // [GIVEN]   1
        // [GIVEN]  / \
        // [GIVEN] 2   3
        // [GIVEN]  \ /
        // [GIVEN]   4
        SetNextOperationNo(RoutingLine[1], StrSubstNo('%1|%2', RoutingLine[2]."Operation No.", RoutingLine[3]."Operation No."));
        SetNextOperationNo(RoutingLine[2], RoutingLine[4]."Operation No.");
        SetNextOperationNo(RoutingLine[3], RoutingLine[4]."Operation No.");

        // [WHEN] Certify the routing
        CertifyRoutingAndRefreshLines(RoutingHeader, RoutingLine);

        // [THEN] "Sequence No. (Forward)" in operation 1 is "1", "Sequence No. (Backward)" is "3"
        // [THEN] The following sequence is generated:
        // [THEN]  "Sequence No. (Forward)": 1           "Sequence No. (Backward)": 3
        // [THEN]                           / \                                    / \
        // [THEN]                          2   2                                  2   2
        // [THEN]                           \ /                                    \ /
        // [THEN]                            3                                      1
        RoutingLine[1].TestField("Sequence No. (Forward)", 1);
        RoutingLine[1].TestField("Sequence No. (Backward)", 3);

        RoutingLine[2].TestField("Sequence No. (Forward)", 2);
        RoutingLine[2].TestField("Sequence No. (Backward)", 2);

        RoutingLine[3].TestField("Sequence No. (Forward)", 2);
        RoutingLine[3].TestField("Sequence No. (Backward)", 2);

        RoutingLine[4].TestField("Sequence No. (Forward)", 3);
        RoutingLine[4].TestField("Sequence No. (Backward)", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertifyParallelRoutingImbalancedExecutionTree()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[5] of Record "Routing Line";
        I: Integer;
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO 221561] Verify sequence numbers on two parallel executions paths having different number of operations

        Initialize();

        // [GIVEN] Create a parallel routing with 5 operations
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        for I := 1 to ArrayLen(RoutingLine) do
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[I], '', Format(I), RoutingLine[I].Type::"Work Center", WorkCenter."No.");

        // [GIVEN] Setup the execution path: starting operation 1, operations 2 and 3 are executed in parallel
        // [GIVEN] Operation 4 is executed sequentially after op. 3, both 2 and 4 lead to the terminal operation 5
        // [GIVEN]    1
        // [GIVEN]   / \
        // [GIVEN]  2   3
        // [GIVEN]  |   |
        // [GIVEN]  |   4
        // [GIVEN]   \ /
        // [GIVEN]    5
        SetNextOperationNo(RoutingLine[1], StrSubstNo('%1|%2', RoutingLine[2]."Operation No.", RoutingLine[3]."Operation No."));
        SetNextOperationNo(RoutingLine[2], RoutingLine[5]."Operation No.");
        SetNextOperationNo(RoutingLine[3], RoutingLine[4]."Operation No.");
        SetNextOperationNo(RoutingLine[4], RoutingLine[5]."Operation No.");

        // [WHEN] Certify the routing
        CertifyRoutingAndRefreshLines(RoutingHeader, RoutingLine);

        // [THEN] The following sequence is generated:
        // [THEN]  "Sequence No. (Forward)": 1           "Sequence No. (Backward)": 4
        // [THEN]                           / \                                    / \
        // [THEN]                          2   2                                  2   3
        // [THEN]                          |   |                                  |   |
        // [THEN]                          |   3                                  |   2
        // [THEN]                           \ /                                    \ /
        // [THEN]                            4                                      1
        RoutingLine[1].TestField("Sequence No. (Forward)", 1);
        RoutingLine[1].TestField("Sequence No. (Backward)", 4);

        RoutingLine[2].TestField("Sequence No. (Forward)", 2);
        RoutingLine[2].TestField("Sequence No. (Backward)", 2);

        RoutingLine[3].TestField("Sequence No. (Forward)", 2);
        RoutingLine[3].TestField("Sequence No. (Backward)", 3);

        RoutingLine[4].TestField("Sequence No. (Forward)", 3);
        RoutingLine[4].TestField("Sequence No. (Backward)", 2);

        RoutingLine[5].TestField("Sequence No. (Forward)", 4);
        RoutingLine[5].TestField("Sequence No. (Backward)", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertifyParallelRoutingLongWayPointsToShortWay()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[5] of Record "Routing Line";
        i: Integer;
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO 340158] Sequence numbers on two parallel execution paths of different lengths, long way points to short way.
        Initialize();

        // [GIVEN] Create a parallel routing with 5 operations
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        for i := 1 to ArrayLen(RoutingLine) do
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[i], '', Format(i), RoutingLine[i].Type::"Work Center", WorkCenter."No.");

        // [GIVEN] Setup the execution path: starting operation 1, operations 2 and 5 are executed in parallel.
        // [GIVEN] Way A: 1 → 2 → 3 → 4 → 5; Way B: 1 → 5. Termination operation 5.
        // [GIVEN]   1
        // [GIVEN]  / \ 
        // [GIVEN] 5   2
        // [GIVEN] ↑   ↓
        // [GIVEN]  \  3
        // [GIVEN]   \ ↓
        // [GIVEN]     4
        SetNextOperationNo(RoutingLine[1], StrSubstNo('%1|%2', RoutingLine[2]."Operation No.", RoutingLine[5]."Operation No."));
        SetNextOperationNo(RoutingLine[2], RoutingLine[3]."Operation No.");
        SetNextOperationNo(RoutingLine[3], RoutingLine[4]."Operation No.");
        SetNextOperationNo(RoutingLine[4], RoutingLine[5]."Operation No.");

        // [WHEN] Certify the routing
        CertifyRoutingAndRefreshLines(RoutingHeader, RoutingLine);

        // [THEN] The following sequence is generated:
        // [THEN]  "Sequence No. (Forward)": 1           "Sequence No. (Backward)": 5
        // [THEN]                           / \                                    / \
        // [THEN]                          5   2                                  1   4
        // [THEN]                          |   |                                  |   |
        // [THEN]                           \  3                                   \  3
        // [THEN]                            \ |                                    \ |
        // [THEN]                              4                                      2
        RoutingLine[1].TestField("Sequence No. (Forward)", 1);
        RoutingLine[2].TestField("Sequence No. (Forward)", 2);
        RoutingLine[3].TestField("Sequence No. (Forward)", 3);
        RoutingLine[4].TestField("Sequence No. (Forward)", 4);
        RoutingLine[5].TestField("Sequence No. (Forward)", 5);

        RoutingLine[5].TestField("Sequence No. (Backward)", 1);
        RoutingLine[4].TestField("Sequence No. (Backward)", 2);
        RoutingLine[3].TestField("Sequence No. (Backward)", 3);
        RoutingLine[2].TestField("Sequence No. (Backward)", 4);
        RoutingLine[1].TestField("Sequence No. (Backward)", 5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertifyParallelRoutingShortWayPointsToLongWay()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[5] of Record "Routing Line";
        i: Integer;
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO 340158] Sequence numbers on two parallel execution paths of different lengths, short way points to long way.
        Initialize();

        // [GIVEN] Create a parallel routing with 5 operations
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        for i := 1 to ArrayLen(RoutingLine) do
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[i], '', Format(i), RoutingLine[i].Type::"Work Center", WorkCenter."No.");

        // [GIVEN] Setup the execution path: starting operation 1, operations 2 and 3 are executed in parallel.
        // [GIVEN] Way A: 1 → 2; Way B: 1 → 3 → 4 → 5. Termination operation 5.
        // [GIVEN]   1
        // [GIVEN]  / \ 
        // [GIVEN] 2 → 3
        // [GIVEN]     ↓
        // [GIVEN]     4
        // [GIVEN]     ↓
        // [GIVEN]     5
        SetNextOperationNo(RoutingLine[1], StrSubstNo('%1|%2', RoutingLine[2]."Operation No.", RoutingLine[3]."Operation No."));
        SetNextOperationNo(RoutingLine[2], RoutingLine[3]."Operation No.");
        SetNextOperationNo(RoutingLine[3], RoutingLine[4]."Operation No.");
        SetNextOperationNo(RoutingLine[4], RoutingLine[5]."Operation No.");

        // [WHEN] Certify the routing
        CertifyRoutingAndRefreshLines(RoutingHeader, RoutingLine);

        // [THEN] The following sequence is generated:
        // [THEN]  "Sequence No. (Forward)": 1           "Sequence No. (Backward)": 5
        // [THEN]                           / \                                    / \
        // [THEN]                          2 - 3                                  4 - 3
        // [THEN]                              |                                      |
        // [THEN]                              4                                      2
        // [THEN]                              |                                      |
        // [THEN]                              5                                      1
        RoutingLine[1].TestField("Sequence No. (Forward)", 1);
        RoutingLine[2].TestField("Sequence No. (Forward)", 2);
        RoutingLine[3].TestField("Sequence No. (Forward)", 3);
        RoutingLine[4].TestField("Sequence No. (Forward)", 4);
        RoutingLine[5].TestField("Sequence No. (Forward)", 5);

        RoutingLine[5].TestField("Sequence No. (Backward)", 1);
        RoutingLine[4].TestField("Sequence No. (Backward)", 2);
        RoutingLine[3].TestField("Sequence No. (Backward)", 3);
        RoutingLine[2].TestField("Sequence No. (Backward)", 4);
        RoutingLine[1].TestField("Sequence No. (Backward)", 5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertifyParallelRoutingDottedFilterInNextOperationNo()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[7] of Record "Routing Line";
        i: Integer;
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO 340158] Sequence numbers on multiple parallel execution paths of different lengths. "Next Operation No." contains filter 2..5
        Initialize();

        // [GIVEN] Create a parallel routing with 5 operations
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        for i := 1 to ArrayLen(RoutingLine) do
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[i], '', Format(i), RoutingLine[i].Type::"Work Center", WorkCenter."No.");

        // [GIVEN] Setup the execution path: starting operation 1, operations 2, 3, 4, 5 are executed in parallel.
        // [GIVEN] Ways: 1 -> 2 -> 7; 1 -> 3 -> 6 -> 7; 1 -> 4 -> 7; 1 -> 5 -> 7. Termination operation 7.
        // [GIVEN]      1
        // [GIVEN]  / /  \ \
        // [GIVEN] 2  3  4  5
        // [GIVEN]    |
        // [GIVEN]    6
        // [GIVEN]    |
        // [GIVEN]    7
        SetNextOperationNo(RoutingLine[1], StrSubstNo('%1..%2', RoutingLine[2]."Operation No.", RoutingLine[5]."Operation No."));
        SetNextOperationNo(RoutingLine[2], RoutingLine[7]."Operation No.");
        SetNextOperationNo(RoutingLine[3], RoutingLine[6]."Operation No.");
        SetNextOperationNo(RoutingLine[4], RoutingLine[7]."Operation No.");
        SetNextOperationNo(RoutingLine[5], RoutingLine[7]."Operation No.");
        SetNextOperationNo(RoutingLine[6], RoutingLine[7]."Operation No.");

        // [WHEN] Certify the routing
        CertifyRoutingAndRefreshLines(RoutingHeader, RoutingLine);

        // [THEN] The following sequence is generated:
        // [THEN]  "Sequence No. (Forward)":    1           "Sequence No. (Backward)":  4
        // [THEN]                           / /  \ \                                 / /  \ \
        // [THEN]                          2  2  2  2                               2  3  2  2
        // [THEN]                             |                                        |
        // [THEN]                             3                                        2
        // [THEN]                             |                                        |
        // [THEN]                             4                                        1
        RoutingLine[1].TestField("Sequence No. (Forward)", 1);
        RoutingLine[2].TestField("Sequence No. (Forward)", 2);
        RoutingLine[3].TestField("Sequence No. (Forward)", 2);
        RoutingLine[4].TestField("Sequence No. (Forward)", 2);
        RoutingLine[5].TestField("Sequence No. (Forward)", 2);
        RoutingLine[6].TestField("Sequence No. (Forward)", 3);
        RoutingLine[7].TestField("Sequence No. (Forward)", 4);

        RoutingLine[7].TestField("Sequence No. (Backward)", 1);
        RoutingLine[6].TestField("Sequence No. (Backward)", 2);
        RoutingLine[5].TestField("Sequence No. (Backward)", 2);
        RoutingLine[4].TestField("Sequence No. (Backward)", 2);
        RoutingLine[3].TestField("Sequence No. (Backward)", 3);
        RoutingLine[2].TestField("Sequence No. (Backward)", 2);
        RoutingLine[1].TestField("Sequence No. (Backward)", 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertifyParallelRoutingWithCrossParallelOperations()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[6] of Record "Routing Line";
        I: Integer;
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO 221561] Verify sequence numbers on two parallel execution paths with cross-sections

        Initialize();

        // [GIVEN] Parallel routing with the following structure
        // [GIVEN]    1
        // [GIVEN]   / \
        // [GIVEN]  2   3
        // [GIVEN]  | X |
        // [GIVEN]  4   5
        // [GIVEN]   \ /
        // [GIVEN]    6
        // [GIVEN] Operation 4 and 5 are both executed in parallel after 2 and 3
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        for I := 1 to ArrayLen(RoutingLine) do
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[I], '', Format(I), RoutingLine[I].Type::"Work Center", WorkCenter."No.");

        SetNextOperationNo(RoutingLine[1], StrSubstNo('%1|%2', RoutingLine[2]."Operation No.", RoutingLine[3]."Operation No."));
        SetNextOperationNo(RoutingLine[2], StrSubstNo('%1|%2', RoutingLine[4]."Operation No.", RoutingLine[5]."Operation No."));
        SetNextOperationNo(RoutingLine[3], StrSubstNo('%1|%2', RoutingLine[4]."Operation No.", RoutingLine[5]."Operation No."));
        SetNextOperationNo(RoutingLine[4], RoutingLine[6]."Operation No.");
        SetNextOperationNo(RoutingLine[5], RoutingLine[6]."Operation No.");

        // [WHEN] Certify the routing
        CertifyRoutingAndRefreshLines(RoutingHeader, RoutingLine);

        // [THEN] The following sequence is generated:
        // [THEN]  "Sequence No. (Forward)": 1           "Sequence No. (Backward)": 4
        // [THEN]                           / \                                    / \
        // [THEN]                          2   2                                  3   3
        // [THEN]                          | X |                                  | X |
        // [THEN]                          3   3                                  2   2
        // [THEN]                           \ /                                    \ /
        // [THEN]                            4                                      1
        RoutingLine[1].TestField("Sequence No. (Forward)", 1);
        RoutingLine[1].TestField("Sequence No. (Backward)", 4);

        RoutingLine[2].TestField("Sequence No. (Forward)", 2);
        RoutingLine[2].TestField("Sequence No. (Backward)", 3);

        RoutingLine[3].TestField("Sequence No. (Forward)", 2);
        RoutingLine[3].TestField("Sequence No. (Backward)", 3);

        RoutingLine[4].TestField("Sequence No. (Forward)", 3);
        RoutingLine[4].TestField("Sequence No. (Backward)", 2);

        RoutingLine[5].TestField("Sequence No. (Forward)", 3);
        RoutingLine[5].TestField("Sequence No. (Backward)", 2);

        RoutingLine[6].TestField("Sequence No. (Forward)", 4);
        RoutingLine[6].TestField("Sequence No. (Backward)", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertifyParallelRoutingFailedWithoutManualSequence()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[2] of Record "Routing Line";
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO 221561] Certification of a parallel routing should fail if "Next Operation No." is not filled on operations

        Initialize();

        // [GIVEN] Create a parallel routing without filling the "Next Operation No." field
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine[1], '', LibraryUtility.GenerateGUID(), RoutingLine[1].Type::"Work Center", WorkCenter."No.");
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine[2], '', LibraryUtility.GenerateGUID(), RoutingLine[2].Type::"Work Center", WorkCenter."No.");

        // [WHEN] Certify the routing
        asserterror ChangeRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [THEN] Certification fails
        Assert.ExpectedError(StrSubstNo(WrongNoOfTerminationProcessesErr, RoutingHeader."No.", 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertifyParallelRoutingFailedWithCircularReference()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[3] of Record "Routing Line";
        I: Integer;
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO 221561] Certification of a parallel routing should fail with an error message if the routing setup contains circular reference

        Initialize();

        // [GIVEN] Create a parallel routing with 3 operations
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        for I := 1 to ArrayLen(RoutingLine) do
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[I], '', Format(I), RoutingLine[I].Type::"Work Center", WorkCenter."No.");

        // [GIVEN] Starting operation 1, next operations 2 and 3 are executed in parallel.
        // [GIVEN] Next operation for op. 2 is 1 (circular reference)
        // [GIVEN]    --1
        // [GIVEN]   \ / \
        // [GIVEN]    2   3
        SetNextOperationNo(RoutingLine[1], StrSubstNo('%1|%2', RoutingLine[2]."Operation No.", RoutingLine[3]."Operation No."));
        SetNextOperationNo(RoutingLine[2], RoutingLine[1]."Operation No.");

        // [WHEN] Certify the routing
        asserterror ChangeRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [THEN] Certification fails. Error message "Circular reference in routing" is thrown.
        Assert.ExpectedError(StrSubstNo(CircularReferenceErr, RoutingHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertifyParallelRoutingNoStartingOperationFail()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[2] of Record "Routing Line";
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO 221561] Certification of a parallel routing should fail if no starting operation is specified in the routing setup

        Initialize();

        // [GIVEN] Create parallel routing with two operations, set "Next Operation No." in both lines
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine[1], '', LibraryUtility.GenerateGUID(), RoutingLine[1].Type::"Work Center", WorkCenter."No.");
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine[2], '', LibraryUtility.GenerateGUID(), RoutingLine[2].Type::"Work Center", WorkCenter."No.");

        SetNextOperationNo(RoutingLine[1], LibraryUtility.GenerateGUID());
        SetNextOperationNo(RoutingLine[2], LibraryUtility.GenerateGUID());

        // [WHEN] Certify the routing
        asserterror ChangeRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [THEN] Certification fails.
        Assert.ExpectedError(NoLineWithinFilterErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertifyParallelRoutingTwoStartingOperationsFail()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[3] of Record "Routing Line";
        I: Integer;
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO 221561] Certification of a parallel routing should fail if the routing setup contains two starting operations

        Initialize();

        // [GIVEN] Create parallel routing with 3 operations
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        for I := 1 to ArrayLen(RoutingLine) do
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[I], '', Format(I), RoutingLine[I].Type::"Work Center", WorkCenter."No.");

        // [GIVEN] In operation 1 and 2, set "Next Operation No." = "3"
        // [GIVEN]  1   2
        // [GIVEN]   \ /
        // [GIVEN]    3
        SetNextOperationNo(RoutingLine[1], RoutingLine[3]."Operation No.");
        SetNextOperationNo(RoutingLine[2], RoutingLine[3]."Operation No.");

        // [WHEN] Certify the routing
        asserterror CertifyRoutingAndRefreshLines(RoutingHeader, RoutingLine);

        // [THEN] Certification fails. Error message: "Actual number of starting processes is 2"
        Assert.ExpectedError(StrSubstNo(WrongNoOfStartProcessesErr, RoutingHeader."No.", 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertifyParallelRoutingTwoTerminalOperationsFail()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[3] of Record "Routing Line";
        I: Integer;
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO 221561] Certification of a parallel routing should fail if the routing setup contains two terminal operations

        Initialize();

        // [GIVEN] Create parallel routing with 3 operations
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        for I := 1 to ArrayLen(RoutingLine) do
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[I], '', Format(I), RoutingLine[I].Type::"Work Center", WorkCenter."No.");

        // [GIVEN] Starting operation - "1", operation "2" and "3" are executed in parallel after it
        // [GIVEN]    1
        // [GIVEN]   / \
        // [GIVEN]  2   3
        SetNextOperationNo(RoutingLine[1], StrSubstNo('%1|%2', RoutingLine[2]."Operation No.", RoutingLine[3]."Operation No."));

        // [WHEN] Certify the routing
        asserterror CertifyRoutingAndRefreshLines(RoutingHeader, RoutingLine);

        // [THEN] Certification fails. Error message: "Actual number of termination processes is 2"
        Assert.ExpectedError(StrSubstNo(WrongNoOfTerminationProcessesErr, RoutingHeader."No.", 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PerformanceOnCerifyingParallelRouting()
    var
        CodeCoverage: Record "Code Coverage";
        SmallNoOfOperations: Integer;
        MediumNoOfOperations: Integer;
        LargeNoOfOperations: Integer;
        SmallNoOfHits: Integer;
        MediumNoOfHits: Integer;
        LargeNoOfHits: Integer;
    begin
        // [FEATURE] [Performance] [Parallel Routing]
        // [SCENARIO 221561] Calculation of routing operations sequence should have linear performance

        Initialize();

        // [GIVEN] Parallel routing with the following structure
        // [GIVEN]     1
        // [GIVEN]    / \
        // [GIVEN]   2   3
        // [GIVEN]    \ /
        // [GIVEN]     4
        // [GIVEN]    / \
        // [GIVEN]   5   6
        // [GIVEN]    \ /
        // [GIVEN]     7
        // [GIVEN]    / \
        // [GIVEN]    ...

        CodeCoverageMgt.StopApplicationCoverage();
        SmallNoOfOperations := 1;
        MediumNoOfOperations := 5;
        LargeNoOfOperations := 10;

        CodeCoverageMgt.StartApplicationCoverage();
        CreateAndCertifyRoutingWithCrossOperations(SmallNoOfOperations);
        CodeCoverageMgt.StopApplicationCoverage();
        SmallNoOfHits :=
          GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Check Routing Lines", 'SetRtngLineSequenceBack') +
          GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Check Routing Lines", 'SetRtngLineSequenceForward');

        CodeCoverageMgt.StartApplicationCoverage();
        CreateAndCertifyRoutingWithCrossOperations(MediumNoOfOperations);
        CodeCoverageMgt.StopApplicationCoverage();
        MediumNoOfHits :=
          GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Check Routing Lines", 'SetRtngLineSequenceBack') +
          GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Check Routing Lines", 'SetRtngLineSequenceForward');

        CodeCoverageMgt.StartApplicationCoverage();
        CreateAndCertifyRoutingWithCrossOperations(LargeNoOfOperations);
        CodeCoverageMgt.StopApplicationCoverage();
        LargeNoOfHits :=
          GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Check Routing Lines", 'SetRtngLineSequenceBack') +
          GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"Check Routing Lines", 'SetRtngLineSequenceForward');

        // [WHEN] Certify the routing
        // [THEN] Performance should be linear
        Assert.IsTrue(
          LibraryCalcComplexity.IsLinear(
            SmallNoOfOperations, MediumNoOfOperations, LargeNoOfOperations, SmallNoOfHits, MediumNoOfHits, LargeNoOfHits),
          NotLinearCCErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculateCapacityOnChangingWorkCenterInParallelRouting()
    var
        WorkCenter: array[2] of Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // [FEATURE] [Parallel Routing] [Capacity]
        // [SCENARIO 272988] Production order routing line is recalculated when the work center is changed for the parallel routing

        Initialize();

        // [GIVEN] Two work centers: "W1" with "Unit Cost" = 10, and "W2" with "Unit Cost" = 20 and "Overhead Rate" = 5
        CreateWorkCenterWithCost(WorkCenter[1], LibraryRandom.RandInt(10), 0);
        CreateWorkCenterWithCost(WorkCenter[2], LibraryRandom.RandIntInRange(15, 25), LibraryRandom.RandInt(5));

        // [GIVEN] Parallel routing with a single line on the work center "W1", "Run Time" = 30 min
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '100', RoutingLine.Type::"Work Center", WorkCenter[1]."No.");
        RoutingLine.Validate("Run Time", LibraryRandom.RandInt(100));
        RoutingLine.Modify(true);
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [GIVEN] Item with the parallel routing assigned
        CreateItemWithRouting(Item, RoutingHeader."No.");

        // [GIVEN] Create and refresh a released production order for 3 pcs of the manufactured item
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(100));
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Operation No.", '100');
        ProdOrderRoutingLine.FindFirst();

        // [WHEN] Open the prod. order routing and change the work center from "W1" to "W2"
        ProdOrderRoutingLine.Validate("No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.Modify(true);

        // [THEN] Capacity requirements and costs are recalculated for the production order.
        // [THEN] Expected operation cost is 3 * 30 * 20 = 1800; Expected capacity overhead is 3 * 30 * 5 = 450
        ProdOrderRoutingLine.Find();
        ProdOrderRoutingLine.TestField(
          "Expected Operation Cost Amt.", ProductionOrder.Quantity * RoutingLine."Run Time" * WorkCenter[2]."Unit Cost");
        ProdOrderRoutingLine.TestField(
          "Expected Capacity Ovhd. Cost", ProductionOrder.Quantity * RoutingLine."Run Time" * WorkCenter[2]."Overhead Rate");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CapacityNotCalculatedOnChangingWorkCenterInNewLineParallelRouting()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ProductionOrder: Record "Production Order";
        Item: Record Item;
    begin
        // [FEATURE] [Parallel Routing]
        // [SCENARIO 272988] Recalculation of the production order routing line is not triggered when a work center is selected in the new line for a parallel routing

        Initialize();

        // [GIVEN] Parallel routing with two operations: "100" and "200"
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '100', RoutingLine.Type::"Work Center", WorkCenter."No.");
        SetNextOperationNo(RoutingLine, '200');
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '200', RoutingLine.Type::"Work Center", WorkCenter."No.");
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [GIVEN] Item with the parallel routing and a released production order for this item
        CreateItemWithRouting(Item, RoutingHeader."No.");
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(100));

        // [GIVEN] Create new prod. order routing line for the same production order. The line does not have operation sequence defined, and thus would cause an error on capacity calculation
        ProdOrderRoutingLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        ProdOrderRoutingLine.Init();
        ProdOrderRoutingLine.Validate("Operation No.", '150');
        ProdOrderRoutingLine.Insert(true);

        // [WHEN] Set the work center no. in the new line
        ProdOrderRoutingLine.Validate("No.", WorkCenter."No.");

        // [THEN] Work center is updated without error
        ProdOrderRoutingLine.TestField("Work Center No.", WorkCenter."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoutingPersonnelCaptionMethodOverflow()
    var
        RoutingHeader: Record "Routing Header";
        RoutingPersonnel: Record "Routing Personnel";
        CaptionText: Text;
    begin
        // [SCENARIO 308562] Caption method throws OverflowError
        Initialize();

        // [GIVEN] Created "Routing Header" with MAXSTRLEN "No." and Description fields
        CreateRtngHeaderWithMaxStrlen(RoutingHeader);

        // [WHEN] Create "Routing Personnel" for this header with MAXSTRLEN "Operation No." field
        CreateRtngPersonnelWithMaxStrlen(RoutingPersonnel, RoutingHeader);
        RoutingPersonnel.SetFilter("Routing No.", RoutingHeader."No.");

        // [THEN] Caption method doesn't throw OverflowError and returns expected value
        CaptionText := StrSubstNo('%1 %2 %3', RoutingPersonnel."Routing No.",
            RoutingHeader.Description, RoutingPersonnel."Operation No.");
        Assert.AreEqual(CaptionText, RoutingPersonnel.Caption(), '');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeStatusProdOrderWithTrackingAndRoutingWithTwoLinesForward()
    var
        RoutingHeader: Record "Routing Header";
        WorkCenter: Record "Work Center";
        RoutingLine: array[2] of Record "Routing Line";
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        Location: Record Location;
        Index: Integer;
    begin
        // [FEATURE] [Item Tracking] [Order] [Status]
        // [SCENARIO 320285] Change status for Production Order which has Lot Tracked Item with Routing having multiple Lines with Flushing Method Forward
        Initialize();

        // [GIVEN] Certified Routing with two sequent Lines, each had Work Center with Flushing Method Forward
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        for Index := 1 to ArrayLen(RoutingLine) do begin
            LibraryManufacturing.CreateWorkCenter(WorkCenter);
            WorkCenter.Validate("Flushing Method", WorkCenter."Flushing Method"::Forward);
            WorkCenter.Modify(true);
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[Index], '', LibraryUtility.GenerateGUID(), RoutingLine[1].Type::"Work Center", WorkCenter."No.");
        end;
        RoutingLine[1].Validate("Next Operation No.", RoutingLine[2]."Operation No.");
        RoutingLine[1].Modify(true);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        // [GIVEN] Lot Tracked Item with the Routing
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("Lot Specific Tracking", true);
        ItemTrackingCode.Modify(true);
        CreateItemWithRouting(Item, RoutingHeader."No.");
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);

        // [GIVEN] Refreshed Planned Production Order with 10 PCS of the Item
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Planned, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10));
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, true, false);

        // [GIVEN] Fully tracked Prod. Order Line (done in ItemTrackingLinesModalPageHandler)
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SetLotNo);
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(ProdOrderLine."Quantity (Base)");
        ProdOrderLine.OpenItemTrackingLines();

        // [WHEN] Change Order Status to Released
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Released, WorkDate(), false);

        // [THEN] Released Production Order for the Item is created
        ProductionOrder.SetRange("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.SetRange("Source No.", Item."No.");
        ProductionOrder.FindFirst();
        ProductionOrder.TestField(Status, ProductionOrder.Status::Released);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteWorkCenterForCertifiedRouting()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        // [FEATURE] [UT] [Work Center]
        // [SCENARIO 336623] Work Center cannot be deleted when it is a part of a certified routing
        // [SCENARIO 361820] Error "You cannot delete Work Center because there is at least one Routing Line associated with it" is thrown.

        // [GIVEN] Work Center "WKC"
        WorkCenter.Init();
        WorkCenter."No." := LibraryUtility.GenerateGUID();
        WorkCenter.Insert();

        // [GIVEN] Certified Routing "ROUT" with Routing Line for Work Center "WKC"
        MockRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
        MockRoutingLine(RoutingLine, RoutingHeader."No.", '', RoutingLine.Type::"Work Center", WorkCenter."No.");

        // [WHEN] Delete Work Center "WKC"
        asserterror WorkCenter.Delete(true);

        // [THEN] Error is shown: "You cannot delete Work Center WKC because there is at least one Routing Line associated with it"
        Assert.ExpectedError(
          StrSubstNo(CannotDeleteWorkMachineCenterErr, WorkCenter.TableCaption(), WorkCenter."No.", RoutingLine.TableCaption()));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteWorkCenterForCertifiedRoutingVersion()
    var
        RoutingHeader: Record "Routing Header";
        RoutingVersion: Record "Routing Version";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        // [FEATURE] [UT] [Work Center]
        // [SCENARIO 336623] Work Center cannot be deleted when it is a part of a certified routing version
        // [SCENARIO 361820] Error "You cannot delete Work Center because there is at least one Routing Line associated with it" is thrown.

        // [GIVEN] Work Center "WKC"
        WorkCenter.Init();
        WorkCenter."No." := LibraryUtility.GenerateGUID();
        WorkCenter.Insert();

        // [GIVEN] Non-certified Routing "ROUT"
        MockRoutingHeader(RoutingHeader, RoutingHeader.Status::"Under Development");

        // [GIVEN] Certified Routing Version "ROUT","V1" with Routing Line for Work Center "WKC"
        MockRoutingVersion(RoutingVersion, RoutingHeader."No.", RoutingVersion.Status::Certified);
        MockRoutingLine(
          RoutingLine, RoutingVersion."Routing No.", RoutingVersion."Version Code",
          RoutingLine.Type::"Work Center", WorkCenter."No.");

        // [WHEN] Delete Work Center "WKC"
        asserterror WorkCenter.Delete(true);

        // [THEN] Error is shown: "You cannot delete Work Center WKC because there is at least one Routing Line associated with it"
        Assert.ExpectedError(
          StrSubstNo(CannotDeleteWorkMachineCenterErr, WorkCenter.TableCaption(), WorkCenter."No.", RoutingLine.TableCaption()));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteMachineCenterForCertifiedRouting()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        MachineCenter: Record "Machine Center";
    begin
        // [FEATURE] [UT] [Machine Center]
        // [SCENARIO 336623] Machine Center cannot be deleted when it is a part of a certified routing
        // [SCENARIO 361820] Error "You cannot delete Machine Center because there is at least one Routing Line associated with it" is thrown.

        // [GIVEN] Machine Center "MC"
        MachineCenter.Init();
        MachineCenter."No." := LibraryUtility.GenerateGUID();
        MachineCenter.Insert();

        // [GIVEN] Certified Routing "ROUT" with Routing Line for Machine Center "MC"
        MockRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
        MockRoutingLine(RoutingLine, RoutingHeader."No.", '', RoutingLine.Type::"Machine Center", MachineCenter."No.");

        // [WHEN] Delete Machine Center "MC"
        asserterror MachineCenter.Delete(true);

        // [THEN] Error is shown: "You cannot delete Machine Center MC because there is at least one Routing Line associated with it"
        Assert.ExpectedError(
          StrSubstNo(CannotDeleteWorkMachineCenterErr, MachineCenter.TableCaption(), MachineCenter."No.", RoutingLine.TableCaption()));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteMachineCenterForCertifiedRoutingVersion()
    var
        RoutingHeader: Record "Routing Header";
        RoutingVersion: Record "Routing Version";
        RoutingLine: Record "Routing Line";
        MachineCenter: Record "Machine Center";
    begin
        // [FEATURE] [UT] [Machine Center]
        // [SCENARIO 336623] Machine Center cannot be deleted when it is a part of a certified routing version
        // [SCENARIO 361820] Error "You cannot delete Machine Center because there is at least one Routing Line associated with it" is thrown.

        // [GIVEN] Machine Center "MC"
        MachineCenter.Init();
        MachineCenter."No." := LibraryUtility.GenerateGUID();
        MachineCenter.Insert();

        // [GIVEN] Non-certified Routing "ROUT"
        MockRoutingHeader(RoutingHeader, RoutingHeader.Status::"Under Development");

        // [GIVEN] Certified Routing Version "ROUT","V1" with Routing Line for Machine Center "MC"
        MockRoutingVersion(RoutingVersion, RoutingHeader."No.", RoutingVersion.Status::Certified);
        MockRoutingLine(
          RoutingLine, RoutingVersion."Routing No.", RoutingVersion."Version Code",
          RoutingLine.Type::"Machine Center", MachineCenter."No.");

        // [WHEN] Delete Machine Center "C"
        asserterror MachineCenter.Delete(true);

        // [THEN] Error is shown: "You cannot delete Machine Center MC because there is at least one Routing Line associated with it"
        Assert.ExpectedError(
          StrSubstNo(CannotDeleteWorkMachineCenterErr, MachineCenter.TableCaption(), MachineCenter."No.", RoutingLine.TableCaption()));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteWorkCenter()
    var
        WorkCenter: Record "Work Center";
    begin
        // [FEATURE] [Work Center] [UT]
        // [SCENARIO 361820] Delete Work Center that is not associated with any Routing Line.
        Initialize();

        // [GIVEN] Work Center.
        LibraryManufacturing.CreateWorkCenter(WorkCenter);

        // [WHEN] Delete Work Center.
        WorkCenter.Delete(true);

        // [THEN] Work Center was successfully deleted.
        WorkCenter.SetRecFilter();
        Assert.RecordIsEmpty(WorkCenter);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteWorkCenterForRouting()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        // [FEATURE] [Work Center] [UT]
        // [SCENARIO 361820] Delete Work Center that is associated with Routing Line.
        Initialize();

        // [GIVEN] Work Center, that is set for Routing Line of Routing with Status New.
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        MockRoutingHeader(RoutingHeader, RoutingHeader.Status::New);
        MockRoutingLine(RoutingLine, RoutingHeader."No.", '', RoutingLine.Type::"Work Center", WorkCenter."No.");

        // [WHEN] Delete Work Center.
        asserterror WorkCenter.Delete(true);

        // [THEN] Work Center was not deleted. Error "You cannot delete Work Center because there is at least one Routing Line associated with it" was thrown.
        Assert.ExpectedError(
          StrSubstNo(CannotDeleteWorkMachineCenterErr, WorkCenter.TableCaption(), WorkCenter."No.", RoutingLine.TableCaption()));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteMachineCenter()
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        // [FEATURE] [Machine Center] [UT]
        // [SCENARIO 361820] Delete Machine Center that is not associated with any Routing Line.
        Initialize();

        // [GIVEN] Machine Center.
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenter."No.", LibraryRandom.RandDecInRange(1, 5, 2));

        // [WHEN] Delete Machine Center.
        MachineCenter.Delete(true);

        // [THEN] Machine Center was successfully deleted.
        MachineCenter.SetRecFilter();
        Assert.RecordIsEmpty(MachineCenter);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteMachineCenterForRouting()
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        // [FEATURE] [Machine Center] [UT]
        // [SCENARIO 361820] Delete Machine Center that is associated with Routing Line.
        Initialize();

        // [GIVEN] Machine Center, that is set for Routing Line of Routing with Status New.
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenter."No.", LibraryRandom.RandDecInRange(1, 5, 2));
        MockRoutingHeader(RoutingHeader, RoutingHeader.Status::New);
        MockRoutingLine(RoutingLine, RoutingHeader."No.", '', RoutingLine.Type::"Machine Center", MachineCenter."No.");

        // [WHEN] Delete Machine Center.
        asserterror MachineCenter.Delete(true);

        // [THEN] Machine Center was not deleted. Error "You cannot delete Machine Center because there is at least one Routing Line associated with it" was thrown.
        Assert.ExpectedError(
          StrSubstNo(CannotDeleteWorkMachineCenterErr, MachineCenter.TableCaption(), MachineCenter."No.", RoutingLine.TableCaption()));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertifyRoutingWhenWorkCenterNotExist()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        // [FEATURE] [Work Center] [UT]
        // [SCENARIO 361820] Certify Routing with Routing Line that has associated Work Center that does not exist.
        Initialize();

        // [GIVEN] Routing with Routing Line that has associated Work Center "WC" that does not exist.
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", WorkCenter."No.");
        WorkCenter.Delete(false);

        // [WHEN] Certify Routing.
        asserterror ChangeRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [THEN] Routing was not certified. Error "Operation 10 has the Work Center WC that does not exist" was thrown.
        Assert.ExpectedError(
          StrSubstNo(WorkMachineCenterNotExistErr, RoutingLine."Operation No.", WorkCenter.TableCaption(), RoutingLine."No."));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertifyRoutingWhenWorkCenterBlocked()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        // [FEATURE] [Work Center] [UT]
        // [SCENARIO 361820] Certify Routing with Routing Line that has associated blocked Work Center.
        Initialize();

        // [GIVEN] Routing with Routing Line that has associated Work Center "WC" that is Blocked.
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", WorkCenter."No.");
        WorkCenter.Validate(Blocked, true);
        WorkCenter.Modify(true);

        // [WHEN] Certify Routing.
        asserterror ChangeRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [THEN] Routing was not certified. Error "Blocked must be equal to 'No' in Work Center WC" was thrown.
        Assert.ExpectedTestFieldError(WorkCenter.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertifyRoutingWhenMachineCenterNotExist()
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        // [FEATURE] [Machine Center] [UT]
        // [SCENARIO 361820] Certify Routing with Routing Line that has associated Machine Center that does not exist.
        Initialize();

        // [GIVEN] Routing with Routing Line that has associated Machine Center "MC" that does not exist.
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenter."No.", LibraryRandom.RandDecInRange(1, 5, 2));
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Machine Center", MachineCenter."No.");
        MachineCenter.Delete(false);

        // [WHEN] Certify Routing.
        asserterror ChangeRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [THEN] Routing was not certified. Error "Operation 10 has the Machine Center MC that does not exist" was thrown.
        Assert.ExpectedError(
          StrSubstNo(WorkMachineCenterNotExistErr, RoutingLine."Operation No.", MachineCenter.TableCaption(), RoutingLine."No."));
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertifyRoutingWhenMachineCenterBlocked()
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        // [FEATURE] [Machine Center] [UT]
        // [SCENARIO 361820] Certify Routing with Routing Line that has associated blocked Machine Center.
        Initialize();

        // [GIVEN] Routing with Routing Line that has associated Machine Center "MC" that is Blocked.
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenter."No.", LibraryRandom.RandDecInRange(1, 5, 2));
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Machine Center", MachineCenter."No.");
        MachineCenter.Validate(Blocked, true);
        MachineCenter.Modify(true);

        // [WHEN] Certify Routing.
        asserterror ChangeRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [THEN] Routing was not certified. Error "Blocked must be equal to 'No' in Machine Center MC" was thrown.
        Assert.ExpectedTestFieldError(MachineCenter.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [HandlerFunctions('ProductionJournalModalPageHandler,ItemTrackingLinesModalPageHandler,ConfirmHandler,MessageHandler')]
    procedure TotalsOnItemTrackingLinesForPartiallyPostedPrOLineWithBackwardFlushing()
    var
        Location: Record Location;
        RoutingHeader: Record "Routing Header";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        Qty: Decimal;
        QtyToPost: Decimal;
    begin
        // [FEATURE] [Flushing] [Item Tracking] [Prod. Order Line]
        // [SCENARIO 387367] Total quantity on Item Tracking Page for Prod. Order Line ("P") shows "P".Quantity when posted output quantity is less than "P".Quantity.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(11, 20);
        QtyToPost := LibraryRandom.RandInt(10);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Routing with work center set up for backward flushing.
        CreateRoutingWithBackwardFlushedWorkCenter(RoutingHeader);

        // [GIVEN] Lot-tracked item.
        LibraryItemTracking.CreateLotItem(Item);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        // [GIVEN] Production order for 10 pcs.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", Qty);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Open production journal, set lot no. and output quantity = 7. Post output.
        LibraryVariableStorage.Enqueue(QtyToPost);
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [WHEN] Open item tracking lines for the prod. order line.
        // [THEN] Total quantity = 10. Undefined quantity = 3.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::VerifyTotals);
        LibraryVariableStorage.Enqueue(Qty);
        LibraryVariableStorage.Enqueue(Qty - QtyToPost);
        ProdOrderLine.Find();
        ProdOrderLine.OpenItemTrackingLines();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ProductionJournalModalPageHandler,ItemTrackingLinesModalPageHandler,ConfirmHandler,MessageHandler')]
    procedure TotalsOnItemTrackingLinesForOverPostedPrOLineWithBackwardFlushing()
    var
        Location: Record Location;
        RoutingHeader: Record "Routing Header";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        Qty: Decimal;
        QtyToPost: Decimal;
    begin
        // [FEATURE] [Flushing] [Item Tracking] [Prod. Order Line]
        // [SCENARIO 387367] Total quantity on Item Tracking Page for Prod. Order Line ("P") shows posted output quantity when it is greater than "P".Quantity.
        Initialize();
        Qty := LibraryRandom.RandInt(10);
        QtyToPost := LibraryRandom.RandIntInRange(11, 20);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Routing with work center set up for backward flushing.
        CreateRoutingWithBackwardFlushedWorkCenter(RoutingHeader);

        // [GIVEN] Lot-tracked item.
        LibraryItemTracking.CreateLotItem(Item);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        // [GIVEN] Production order for 10 pcs.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", Qty);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Open production journal, set lot no. and output quantity = 13. Post output.
        LibraryVariableStorage.Enqueue(QtyToPost);
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [WHEN] Open item tracking lines for the prod. order line.
        // [THEN] Total quantity = 13. Undefined quantity = 0.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::VerifyTotals);
        LibraryVariableStorage.Enqueue(QtyToPost);
        LibraryVariableStorage.Enqueue(0);
        ProdOrderLine.Find();
        ProdOrderLine.OpenItemTrackingLines();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure ConcurrentCapacityFilledInCapacityLedgEntryOnFlushing()
    var
        Location: Record Location;
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        // [FEATURE] [Flushing]
        // [SCENARIO 415018] Concurrent Capacity is filled in Capacity Ledger Entry on flushing production order.
        Initialize();

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Routing with backword flushed work center.
        // [GIVEN] Manufacturing item with the routing.
        CreateRoutingWithBackwardFlushedWorkCenter(RoutingHeader);
        CreateItemWithRouting(Item, RoutingHeader."No.");

        // [GIVEN] Released production order, refresh.
        // [GIVEN] Verify that "Concurrent Capacities" on the prod. order routing line is not 0.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10));
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        ProdOrderRoutingLine.FindFirst();
        ProdOrderRoutingLine.TestField("Concurrent Capacities");

        // [WHEN] Finish the production order.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] "Concurrent Capacity" in Capacity Ledger Entry is the same as in the prod. order routing line.
        CapacityLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        CapacityLedgerEntry.SetRange("Routing No.", RoutingHeader."No.");
        CapacityLedgerEntry.SetRange("Item No.", Item."No.");
        CapacityLedgerEntry.FindFirst();
        CapacityLedgerEntry.TestField("Concurrent Capacity", ProdOrderRoutingLine."Concurrent Capacities");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoutingLineRelatedActionsEmptyOperationNo()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingPage: TestPage Routing;
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO 418887] Routing line related actions are disabled for routing line with empty "Operation No." on Routing page
        Initialize();

        // [GIVEN] Create routing "R" 
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        // [GIVEN] Mock routing line with empty "Operation No."
        MockRoutingLineOperationNo(RoutingLine, RoutingHeader."No.", '', '');

        // [WHEN] Routing page is being opened for "R"
        RoutingPage.OpenEdit();
        RoutingPage.Filter.SetFilter("No.", RoutingHeader."No.");

        // [THEN] Line related actions are disabled
        Assert.IsFalse(RoutingPage.RoutingLine."Co&mments".Enabled(), ActionMustBeDisabledErr);
        Assert.IsFalse(RoutingPage.RoutingLine."&Tools".Enabled(), ActionMustBeDisabledErr);
        Assert.IsFalse(RoutingPage.RoutingLine."&Personnel".Enabled(), ActionMustBeDisabledErr);
        Assert.IsFalse(RoutingPage.RoutingLine."&Quality Measures".Enabled(), ActionMustBeDisabledErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoutingLineRelatedActionsNotEmptyOperationNo()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingPage: TestPage Routing;
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO 418887] Routing line related actions are enabled for routing line with not empty "Operation No." on Routing page
        Initialize();

        // [GIVEN] Create routing "R" 
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        // [GIVEN] Mock routing line with not empty "Operation No."
        MockRoutingLineOperationNo(RoutingLine, RoutingHeader."No.", '', LibraryUtility.GenerateGUID());

        // [WHEN] Routing page is being opened for "R"
        RoutingPage.OpenEdit();
        RoutingPage.Filter.SetFilter("No.", RoutingHeader."No.");

        // [THEN] Line related actions are enabled
        Assert.IsTrue(RoutingPage.RoutingLine."Co&mments".Enabled(), ActionMustBeEnabledErr);
        Assert.IsTrue(RoutingPage.RoutingLine."&Tools".Enabled(), ActionMustBeEnabledErr);
        Assert.IsTrue(RoutingPage.RoutingLine."&Personnel".Enabled(), ActionMustBeEnabledErr);
        Assert.IsTrue(RoutingPage.RoutingLine."&Quality Measures".Enabled(), ActionMustBeEnabledErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoutingVersionLineRelatedActionsEmptyOperationNo()
    var
        RoutingHeader: Record "Routing Header";
        RoutingVersion: Record "Routing Version";
        RoutingLine: Record "Routing Line";
        RoutingVersionPage: TestPage "Routing Version";
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO 418887] Routing line related actions are disabled for routing line with empty "Operation No." on Routing Version page
        Initialize();

        // [GIVEN] Create routing "R" 
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        // [GIVEN] Create routing version "RV" 
        LibraryManufacturing.CreateRoutingVersion(RoutingVersion, RoutingHeader."No.", Format(LibraryRandom.RandInt(5)));
        // [GIVEN] Mock routing line with empty "Operation No."
        MockRoutingLineOperationNo(RoutingLine, RoutingHeader."No.", RoutingVersion."Version Code", '');

        // [WHEN] Routing version page is being opened for "RV"
        RoutingVersionPage.OpenEdit();
        RoutingVersionPage.Filter.SetFilter("Routing No.", RoutingHeader."No.");

        // [THEN] Line related actions are disabled
        Assert.IsFalse(RoutingVersionPage.RoutingLine."Co&mments".Enabled(), ActionMustBeDisabledErr);
        Assert.IsFalse(RoutingVersionPage.RoutingLine.Tools.Enabled(), ActionMustBeDisabledErr);
        Assert.IsFalse(RoutingVersionPage.RoutingLine.Personnel.Enabled(), ActionMustBeDisabledErr);
        Assert.IsFalse(RoutingVersionPage.RoutingLine."Quality Measures".Enabled(), ActionMustBeDisabledErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoutingVersionLineRelatedActionsNotEmptyOperationNo()
    var
        RoutingHeader: Record "Routing Header";
        RoutingVersion: Record "Routing Version";
        RoutingLine: Record "Routing Line";
        RoutingVersionPage: TestPage "Routing Version";
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO 418887] Routing line related actions are enabled for routing line with not empty "Operation No." on Routing Version page
        Initialize();

        // [GIVEN] Create routing "R" 
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        // [GIVEN] Create routing version "RV" 
        LibraryManufacturing.CreateRoutingVersion(RoutingVersion, RoutingHeader."No.", Format(LibraryRandom.RandInt(5)));
        // [GIVEN] Mock routing line with not empty "Operation No."
        MockRoutingLineOperationNo(RoutingLine, RoutingHeader."No.", RoutingVersion."Version Code", LibraryUtility.GenerateGUID());

        // [WHEN] Routing version page is being opened for "RV"
        RoutingVersionPage.OpenEdit();
        RoutingVersionPage.Filter.SetFilter("Routing No.", RoutingHeader."No.");

        // [THEN] Line related actions are enabled
        Assert.IsTrue(RoutingVersionPage.RoutingLine."Co&mments".Enabled(), ActionMustBeEnabledErr);
        Assert.IsTrue(RoutingVersionPage.RoutingLine.Tools.Enabled(), ActionMustBeEnabledErr);
        Assert.IsTrue(RoutingVersionPage.RoutingLine.Personnel.Enabled(), ActionMustBeEnabledErr);
        Assert.IsTrue(RoutingVersionPage.RoutingLine."Quality Measures".Enabled(), ActionMustBeEnabledErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure UnitCostPerNotEditableForMachineCenterWithSpecificUnitCostWorkCenter()
    var
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: array[2] of Record "Machine Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Routing: TestPage Routing;
    begin
        // [FEATURE] [Machine Center] [Work Center] [UI]
        // [SCENARIO 432680] "Unit Cost Per" on routing line is not editable for machine center belonging to a work center with "Specific Unit Cost" = TRUE.
        Initialize();

        LibraryManufacturing.CreateWorkCenter(WorkCenter[1]);
        LibraryManufacturing.CreateWorkCenter(WorkCenter[2]);
        WorkCenter[2].Validate("Specific Unit Cost", true);
        WorkCenter[2].Modify(true);

        LibraryManufacturing.CreateMachineCenter(MachineCenter[1], WorkCenter[1]."No.", 1);
        LibraryManufacturing.CreateMachineCenter(MachineCenter[2], WorkCenter[2]."No.", 1);

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', Format(1), RoutingLine.Type::"Machine Center", MachineCenter[1]."No.");
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', Format(2), RoutingLine.Type::"Machine Center", MachineCenter[2]."No.");
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', Format(3), RoutingLine.Type::"Work Center", WorkCenter[2]."No.");

        Routing.OpenEdit();
        Routing.FILTER.SetFilter("No.", RoutingHeader."No.");

        Routing.RoutingLine.First();
        Routing.RoutingLine."No.".AssertEquals(MachineCenter[1]."No.");
        Assert.IsFalse(Routing.RoutingLine."Unit Cost per".Editable(), '');

        Routing.RoutingLine.Next();
        Routing.RoutingLine."No.".AssertEquals(MachineCenter[2]."No.");
        Assert.IsFalse(Routing.RoutingLine."Unit Cost per".Editable(), '');

        Routing.RoutingLine.Next();
        Routing.RoutingLine."No.".AssertEquals(WorkCenter[2]."No.");
        Assert.IsTrue(Routing.RoutingLine."Unit Cost per".Editable(), '');

        Routing.Close();
    end;

    [Test]
    procedure UnitCostPerIsResetWhenChangingNoOnRoutingLine()
    var
        WorkCenter: array[2] of Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 432680] "Unit Cost Per" on routing line is reset when changing "No."
        Initialize();

        LibraryManufacturing.CreateWorkCenter(WorkCenter[1]);
        LibraryManufacturing.CreateWorkCenter(WorkCenter[2]);

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', Format(1), RoutingLine.Type::"Work Center", WorkCenter[1]."No.");
        RoutingLine.Validate("Unit Cost per", LibraryRandom.RandDec(100, 2));

        RoutingLine.Validate("No.", WorkCenter[2]."No.");

        RoutingLine.TestField("Unit Cost per", 0);
    end;

    [Test]
    procedure VerifyQueueTimeOnProdOrderRoutingCorrespondToWCQueueTimeForParallelRouting()
    var
        WorkCenter: array[4] of Record "Work Center";
        CapacityUnitOfMeasure: array[2] of Record "Capacity Unit of Measure";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingVersion: Record "Routing Version";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderLine: Record "Prod. Order Line";
        RoutingLineCopyLines: Codeunit "Routing Line-Copy Lines";
        LeadTimeMgt: Codeunit "Lead-Time Management";
        CurrWorkDate: Date;
        StartingDateTime, EndingDateTime : DateTime;
        ItemNo: Code[20];
        ShopCalendarCode: Code[10];
    begin
        // [SCENARIO 465575] Verify Queue Time on Production Order Routing correspond to work center queue time when routing type is parallel with routing version
        Initialize();

        // [GIVEN] Capacity Unit of Measure in Days
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure[1], CapacityUnitOfMeasure[1].Type::Minutes);
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure[2], CapacityUnitOfMeasure[2].Type::Days);

        // [GIVEN] Calendar with working days from 8AM till 4PM
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarFullWorkingWeekCustomTime(080000T, 160000T);

        // [GIVEN] Four work centers with Queue Times for unit of measure DAYS
        CreateWorkCenterWithCalendarForDAYS(WorkCenter[1], 1, CapacityUnitOfMeasure[1].Code, CapacityUnitOfMeasure[2].Code, ShopCalendarCode);
        CreateWorkCenterWithCalendarForDAYS(WorkCenter[2], 0, CapacityUnitOfMeasure[1].Code, '', ShopCalendarCode);
        CreateWorkCenterWithCalendarForDAYS(WorkCenter[3], 0.5, CapacityUnitOfMeasure[1].Code, CapacityUnitOfMeasure[2].Code, ShopCalendarCode);
        CreateWorkCenterWithCalendarForDAYS(WorkCenter[4], 2, CapacityUnitOfMeasure[1].Code, CapacityUnitOfMeasure[2].Code, ShopCalendarCode);

        // [GIVEN] Set Working Date
        CurrWorkDate := WorkDate();
        System.WorkDate(DMY2Date(27, 2, Date2DMY(Today(), 3)));

        // [GIVEN] Create a routing with 10 operations
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", WorkCenter[1]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '20', RoutingLine.Type::"Work Center", WorkCenter[3]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '50', RoutingLine.Type::"Work Center", WorkCenter[3]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '55', RoutingLine.Type::"Work Center", WorkCenter[4]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '56', RoutingLine.Type::"Work Center", WorkCenter[2]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '60', RoutingLine.Type::"Work Center", WorkCenter[3]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '61', RoutingLine.Type::"Work Center", WorkCenter[2]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '70', RoutingLine.Type::"Work Center", WorkCenter[4]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '90', RoutingLine.Type::"Work Center", WorkCenter[1]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '99', RoutingLine.Type::"Work Center", WorkCenter[2]."No.");

        LibraryManufacturing.CreateRoutingVersion(RoutingVersion, RoutingHeader."No.", RoutingHeader."No.");
        RoutingLineCopyLines.CopyRouting(RoutingVersion."Routing No.", '', RoutingHeader, RoutingVersion."Version Code");

        // [GIVEN] Change routing type to Parallel        
        RoutingVersion.Validate(Type, RoutingVersion.Type::Parallel);
        RoutingVersion.Modify();

        // [GIVEN] Setup sequential execution of the operations by filling the previous and next operation no.
        UpdateSequentialExecution(RoutingVersion."Routing No.", RoutingVersion."Version Code", '10', '', '20|60', 100);
        UpdateSequentialExecution(RoutingVersion."Routing No.", RoutingVersion."Version Code", '20', '10', '50|55', 240);
        UpdateSequentialExecution(RoutingVersion."Routing No.", RoutingVersion."Version Code", '50', '20', '56', 180);
        UpdateSequentialExecution(RoutingVersion."Routing No.", RoutingVersion."Version Code", '55', '20', '56', 60);
        UpdateSequentialExecution(RoutingVersion."Routing No.", RoutingVersion."Version Code", '56', '50|55', '61', 0);
        UpdateSequentialExecution(RoutingVersion."Routing No.", RoutingVersion."Version Code", '60', '10', '61', 240);
        UpdateSequentialExecution(RoutingVersion."Routing No.", RoutingVersion."Version Code", '61', '56|60', '70|90', 0);
        UpdateSequentialExecution(RoutingVersion."Routing No.", RoutingVersion."Version Code", '70', '61', '99', 10320);
        UpdateSequentialExecution(RoutingVersion."Routing No.", RoutingVersion."Version Code", '90', '61', '99', 780);
        UpdateSequentialExecution(RoutingVersion."Routing No.", RoutingVersion."Version Code", '99', '70|90', '', 120);

        // [GIVEN] Certiy Routing Version
        RoutingVersion.Validate(Status, RoutingVersion.Status::Certified);
        RoutingVersion.Modify();

        // [GIVEN] Item with Routing No. and without Production BOM
        ItemNo := CreateItemWithRoutingAndProductionBOM(RoutingVersion."Routing No.", '');

        // [GIVEN] Create and refresh Released Production Order with due date current_year-05-11
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, ItemNo, 1);
        ProductionOrder.Validate("Due Date", DMY2Date(11, 5, Date2DMY(WorkDate(), 3)));
        ProductionOrder."Ending Date" :=
            LeadTimeMgt.GetPlannedEndingDate(
                ProductionOrder."Source No.", ProductionOrder."Location Code", '', ProductionOrder."Due Date", '', "Requisition Ref. Order Type"::"Prod. Order");
        ProductionOrder."Starting Date" := ProductionOrder."Ending Date";
        ProductionOrder."Starting Date-Time" := CreateDateTime(ProductionOrder."Starting Date", ProductionOrder."Starting Time");
        ProductionOrder."Ending Date-Time" := CreateDateTime(ProductionOrder."Ending Date", ProductionOrder."Ending Time");
        ProductionOrder.Modify();

        // [WHEN] Refersh Production Order backward
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [THEN] Verify Production Order Routing starting and ending time
        // Verify ending time of operation '61' is equal to starting time of operation '70'
        ProdOrderRoutingLine.Get(ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Routing Reference No.", RoutingVersion."Routing No.", '61');
        EndingDateTime := ProdOrderRoutingLine."Ending Date-Time";
        ProdOrderRoutingLine.Get(ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Routing Reference No.", RoutingVersion."Routing No.", '70');
        StartingDateTime := ProdOrderRoutingLine."Starting Date-Time";
        Assert.AreEqual(DT2Time(StartingDateTime), DT2Time(EndingDateTime), 'Operation 70 doesn''t start when operation 61 is finished');

        // Verify ending time of operation '20' is equal to starting time of operation '55'
        ProdOrderRoutingLine.Get(ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Routing Reference No.", RoutingVersion."Routing No.", '20');
        EndingDateTime := ProdOrderRoutingLine."Ending Date-Time";
        ProdOrderRoutingLine.Get(ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Routing Reference No.", RoutingVersion."Routing No.", '55');
        StartingDateTime := ProdOrderRoutingLine."Starting Date-Time";
        Assert.AreEqual(DT2Time(StartingDateTime), DT2Time(EndingDateTime), 'Operation 55 doesn''t start when operation 20 is finished');

        // Verfiy ending date-time of first operation '10' is less then starting date-time of the operation '20'
        ProdOrderRoutingLine.Get(ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Routing Reference No.", RoutingHeader."No.", '10');
        EndingDateTime := ProdOrderRoutingLine."Ending Date-Time";
        ProdOrderRoutingLine.Get(ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Routing Reference No.", RoutingHeader."No.", '20');
        StartingDateTime := ProdOrderRoutingLine."Starting Date-Time";
        Assert.IsTrue(EndingDateTime < StartingDateTime, 'First operation ends after next one starts');

        //Restore working date
        System.WorkDate(CurrWorkDate);
    end;

    [Test]
    procedure VerifyQueueTimeOnProdOrderRoutingWCQueueTimeForParallelRoutingSingleNextOperation()
    var
        WorkCenter: Record "Work Center";
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingVersion: Record "Routing Version";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderLine: Record "Prod. Order Line";
        RoutingLineCopyLines: Codeunit "Routing Line-Copy Lines";
        StartingDateTime, EndingDateTime : DateTime;
        ItemNo: Code[20];
        ShopCalendarCode: Code[10];
    begin
        // [SCENARIO 475108] Verify Queue Time on Production Order Routing correspond to work center queue time when routing type is parallel with routing version and without multiple next operations
        Initialize();

        // [GIVEN] Capacity Unit of Measure in Days
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, CapacityUnitOfMeasure.Type::Days);

        // [GIVEN] Calendar with working days from 8AM till 4PM
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarFullWorkingWeekCustomTime(080000T, 160000T);

        // [GIVEN] Work center with Queue Times for unit of measure DAYS
        CreateWorkCenterWithCalendarForDAYS(WorkCenter, 1, CapacityUnitOfMeasure.Code, CapacityUnitOfMeasure.Code, ShopCalendarCode);

        // [GIVEN] Create a routing with 5 operations
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", WorkCenter."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '20', RoutingLine.Type::"Work Center", WorkCenter."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '50', RoutingLine.Type::"Work Center", WorkCenter."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '55', RoutingLine.Type::"Work Center", WorkCenter."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '99', RoutingLine.Type::"Work Center", WorkCenter."No.");

        LibraryManufacturing.CreateRoutingVersion(RoutingVersion, RoutingHeader."No.", RoutingHeader."No.");
        RoutingLineCopyLines.CopyRouting(RoutingVersion."Routing No.", '', RoutingHeader, RoutingVersion."Version Code");

        // [GIVEN] Change routing type to Parallel        
        RoutingVersion.Validate(Type, RoutingVersion.Type::Parallel);
        RoutingVersion.Modify();

        // [GIVEN] Setup sequential execution of the operations by filling the previous and next operation no.
        UpdateSequentialExecution(RoutingVersion."Routing No.", RoutingVersion."Version Code", '10', '', '20|50|55', 10);
        UpdateSequentialExecution(RoutingVersion."Routing No.", RoutingVersion."Version Code", '20', '10', '99', 10);
        UpdateSequentialExecution(RoutingVersion."Routing No.", RoutingVersion."Version Code", '50', '10', '99', 10);
        UpdateSequentialExecution(RoutingVersion."Routing No.", RoutingVersion."Version Code", '55', '10', '99', 10);
        UpdateSequentialExecution(RoutingVersion."Routing No.", RoutingVersion."Version Code", '99', '20|50|55', '', 10);

        // [GIVEN] Certiy Routing Version
        RoutingVersion.Validate(Status, RoutingVersion.Status::Certified);
        RoutingVersion.Modify();

        // [GIVEN] Item with Routing No. and without Production BOM
        ItemNo := CreateItemWithRoutingAndProductionBOM(RoutingVersion."Routing No.", '');

        // [GIVEN] Create and refresh Released Production Order with due date current_year-05-11
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, ItemNo, 1);

        // [WHEN] Refersh Production Order backward
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [THEN] Verify Production Order Routing starting and ending time
        // Verfiy ending date-time of first operation '10' is less then starting date-time of the operation '20'
        ProdOrderRoutingLine.Get(ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Routing Reference No.", RoutingHeader."No.", '10');
        EndingDateTime := ProdOrderRoutingLine."Ending Date-Time";
        ProdOrderRoutingLine.Get(ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Routing Reference No.", RoutingHeader."No.", '20');
        StartingDateTime := ProdOrderRoutingLine."Starting Date-Time";
        Assert.IsTrue(EndingDateTime < StartingDateTime, 'First operation ends after next one starts');

        // Verfiy starting date-time of next operations are equal
        ProdOrderRoutingLine.Get(ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Routing Reference No.", RoutingHeader."No.", '20');
        StartingDateTime := ProdOrderRoutingLine."Starting Date-Time";
        ProdOrderRoutingLine.Get(ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Routing Reference No.", RoutingHeader."No.", '50');
        Assert.AreEqual(StartingDateTime, ProdOrderRoutingLine."Starting Date-Time", 'Oprerations doesn''t start at the same date-time');

        ProdOrderRoutingLine.Get(ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Routing Reference No.", RoutingHeader."No.", '20');
        StartingDateTime := ProdOrderRoutingLine."Starting Date-Time";
        ProdOrderRoutingLine.Get(ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Routing Reference No.", RoutingHeader."No.", '55');
        Assert.AreEqual(StartingDateTime, ProdOrderRoutingLine."Starting Date-Time", 'Oprerations doesn''t start at the same date-time');
    end;

    [Test]
    procedure VerifyQueueTimeOnProdOrderRoutingCorrespondToWCQueueTimeForParallelRoutingWithoutVersion()
    var
        WorkCenter: array[4] of Record "Work Center";
        CapacityUnitOfMeasure: array[2] of Record "Capacity Unit of Measure";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderLine: Record "Prod. Order Line";
        LeadTimeMgt: Codeunit "Lead-Time Management";
        CurrWorkDate: Date;
        StartingDateTime, EndingDateTime : DateTime;
        ItemNo: Code[20];
        ShopCalendarCode: Code[10];
    begin
        // [SCENARIO 465575] Verify Queue Time on Production Order Routing correspond to work center queue time when routing type is parallel without routing version
        Initialize();

        // [GIVEN] Capacity Unit of Measure in Days
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure[1], CapacityUnitOfMeasure[1].Type::Minutes);
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure[2], CapacityUnitOfMeasure[2].Type::Days);

        // [GIVEN] Calendar with working days from 8AM till 4PM
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarFullWorkingWeekCustomTime(080000T, 160000T);

        // [GIVEN] Four work centers with Queue Times for unit of measure DAYS
        CreateWorkCenterWithCalendarForDAYS(WorkCenter[1], 1, CapacityUnitOfMeasure[1].Code, CapacityUnitOfMeasure[2].Code, ShopCalendarCode);
        CreateWorkCenterWithCalendarForDAYS(WorkCenter[2], 0, CapacityUnitOfMeasure[1].Code, '', ShopCalendarCode);
        CreateWorkCenterWithCalendarForDAYS(WorkCenter[3], 0.5, CapacityUnitOfMeasure[1].Code, CapacityUnitOfMeasure[2].Code, ShopCalendarCode);
        CreateWorkCenterWithCalendarForDAYS(WorkCenter[4], 2, CapacityUnitOfMeasure[1].Code, CapacityUnitOfMeasure[2].Code, ShopCalendarCode);

        // [GIVEN] Set Working Date
        CurrWorkDate := WorkDate();
        System.WorkDate(DMY2Date(27, 2, Date2DMY(Today(), 3)));

        // [GIVEN] Create a routing with 10 operations
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", WorkCenter[1]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '20', RoutingLine.Type::"Work Center", WorkCenter[3]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '50', RoutingLine.Type::"Work Center", WorkCenter[3]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '55', RoutingLine.Type::"Work Center", WorkCenter[4]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '56', RoutingLine.Type::"Work Center", WorkCenter[2]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '60', RoutingLine.Type::"Work Center", WorkCenter[3]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '61', RoutingLine.Type::"Work Center", WorkCenter[2]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '70', RoutingLine.Type::"Work Center", WorkCenter[4]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '90', RoutingLine.Type::"Work Center", WorkCenter[1]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '99', RoutingLine.Type::"Work Center", WorkCenter[2]."No.");

        // [GIVEN] Change routing type to Parallel
        RoutingHeader.Validate(Type, RoutingHeader.Type::Parallel);
        RoutingHeader.Modify();

        // [GIVEN] Setup sequential execution of the operations by filling the previous and next operation no.
        UpdateSequentialExecution(RoutingHeader."No.", '', '10', '', '20|60', 100);
        UpdateSequentialExecution(RoutingHeader."No.", '', '20', '10', '50|55', 240);
        UpdateSequentialExecution(RoutingHeader."No.", '', '50', '20', '56', 180);
        UpdateSequentialExecution(RoutingHeader."No.", '', '55', '20', '56', 60);
        UpdateSequentialExecution(RoutingHeader."No.", '', '56', '50|55', '61', 0);
        UpdateSequentialExecution(RoutingHeader."No.", '', '60', '10', '61', 240);
        UpdateSequentialExecution(RoutingHeader."No.", '', '61', '56|60', '70|90', 0);
        UpdateSequentialExecution(RoutingHeader."No.", '', '70', '61', '99', 10320);
        UpdateSequentialExecution(RoutingHeader."No.", '', '90', '61', '99', 780);
        UpdateSequentialExecution(RoutingHeader."No.", '', '99', '70|90', '', 120);

        // [GIVEN] Certiy Routing Version
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify();

        // [GIVEN] Item with Routing No. and without Production BOM
        ItemNo := CreateItemWithRoutingAndProductionBOM(RoutingHeader."No.", '');

        // [GIVEN] Create and refresh Released Production Order with due date current_year-05-11
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, ItemNo, 1);
        ProductionOrder.Validate("Due Date", DMY2Date(11, 5, Date2DMY(WorkDate(), 3)));
        ProductionOrder."Ending Date" :=
            LeadTimeMgt.GetPlannedEndingDate(
                ProductionOrder."Source No.", ProductionOrder."Location Code", '', ProductionOrder."Due Date", '', "Requisition Ref. Order Type"::"Prod. Order");
        ProductionOrder."Starting Date" := ProductionOrder."Ending Date";
        ProductionOrder."Starting Date-Time" := CreateDateTime(ProductionOrder."Starting Date", ProductionOrder."Starting Time");
        ProductionOrder."Ending Date-Time" := CreateDateTime(ProductionOrder."Ending Date", ProductionOrder."Ending Time");
        ProductionOrder.Modify();

        // [WHEN] Refersh Production Order backward
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [THEN] Verify Production Order Routing starting and ending time
        // Verify ending time of operation '61' is equal to starting time of operation '70'
        ProdOrderRoutingLine.Get(ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Routing Reference No.", RoutingHeader."No.", '61');
        EndingDateTime := ProdOrderRoutingLine."Ending Date-Time";
        ProdOrderRoutingLine.Get(ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Routing Reference No.", RoutingHeader."No.", '70');
        StartingDateTime := ProdOrderRoutingLine."Starting Date-Time";
        Assert.AreEqual(DT2Time(StartingDateTime), DT2Time(EndingDateTime), 'Operation 70 doesn''t start when operation 61 is finished');

        // Verify ending time of operation '20' is equal to starting time of operation '55'
        ProdOrderRoutingLine.Get(ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Routing Reference No.", RoutingHeader."No.", '20');
        EndingDateTime := ProdOrderRoutingLine."Ending Date-Time";
        ProdOrderRoutingLine.Get(ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Routing Reference No.", RoutingHeader."No.", '55');
        StartingDateTime := ProdOrderRoutingLine."Starting Date-Time";
        Assert.AreEqual(DT2Time(StartingDateTime), DT2Time(EndingDateTime), 'Operation 55 doesn''t start when operation 20 is finished');

        // Verfiy ending date-time of first operation '10' is less then starting date-time of the operation '20'
        ProdOrderRoutingLine.Get(ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Routing Reference No.", RoutingHeader."No.", '10');
        EndingDateTime := ProdOrderRoutingLine."Ending Date-Time";
        ProdOrderRoutingLine.Get(ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Routing Reference No.", RoutingHeader."No.", '20');
        StartingDateTime := ProdOrderRoutingLine."Starting Date-Time";
        Assert.IsTrue(EndingDateTime < StartingDateTime, 'First operation ends after next one starts');

        //Restore working date
        System.WorkDate(CurrWorkDate);
    end;

    [Test]
    procedure ChangingDueDateNotGivingAnyErrorWhenReleasedProductionOrderWithParallelRouting()
    var
        WorkCenter: array[4] of Record "Work Center";
        CapacityUnitOfMeasure: array[2] of Record "Capacity Unit of Measure";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ProductionOrder: Record "Production Order";
        LeadTimeMgt: Codeunit "Lead-Time Management";
        ItemNo: Code[20];
        ShopCalendarCode: Code[10];
    begin
        // [SCENARIO 485872] Change Due Date on Released Production Order generated message: The Prod. Order Routing Line does not exist.
        Initialize();

        // [GIVEN] Capacity Unit of Measure in Days
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure[1], CapacityUnitOfMeasure[1].Type::Minutes);
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure[2], CapacityUnitOfMeasure[2].Type::Days);

        // [GIVEN] Calendar with working days from 8AM till 4PM
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarFullWorkingWeekCustomTime(080000T, 160000T);

        // [GIVEN] Four work centers with Queue Times for unit of measure DAYS
        CreateWorkCenterWithCalendarForDAYS(WorkCenter[1], 1, CapacityUnitOfMeasure[1].Code, CapacityUnitOfMeasure[2].Code, ShopCalendarCode);
        CreateWorkCenterWithCalendarForDAYS(WorkCenter[2], 0, CapacityUnitOfMeasure[1].Code, '', ShopCalendarCode);
        CreateWorkCenterWithCalendarForDAYS(WorkCenter[3], 0.5, CapacityUnitOfMeasure[1].Code, CapacityUnitOfMeasure[2].Code, ShopCalendarCode);
        CreateWorkCenterWithCalendarForDAYS(WorkCenter[4], 2, CapacityUnitOfMeasure[1].Code, CapacityUnitOfMeasure[2].Code, ShopCalendarCode);

        // [GIVEN] Create a routing with 10 operations
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", WorkCenter[1]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '20', RoutingLine.Type::"Work Center", WorkCenter[3]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '50', RoutingLine.Type::"Work Center", WorkCenter[3]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '55', RoutingLine.Type::"Work Center", WorkCenter[4]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '56', RoutingLine.Type::"Work Center", WorkCenter[2]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '60', RoutingLine.Type::"Work Center", WorkCenter[3]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '61', RoutingLine.Type::"Work Center", WorkCenter[2]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '70', RoutingLine.Type::"Work Center", WorkCenter[4]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '90', RoutingLine.Type::"Work Center", WorkCenter[1]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '99', RoutingLine.Type::"Work Center", WorkCenter[2]."No.");

        // [GIVEN] Setup sequential execution of the operations by filling the previous and next operation no.
        UpdateSequentialExecution(RoutingHeader."No.", '', '10', '', '20|60', 100);
        UpdateSequentialExecution(RoutingHeader."No.", '', '20', '10', '50|55', 240);
        UpdateSequentialExecution(RoutingHeader."No.", '', '50', '20', '56', 180);
        UpdateSequentialExecution(RoutingHeader."No.", '', '55', '20', '56', 60);
        UpdateSequentialExecution(RoutingHeader."No.", '', '56', '50|55', '61', 0);
        UpdateSequentialExecution(RoutingHeader."No.", '', '60', '10', '61', 240);
        UpdateSequentialExecution(RoutingHeader."No.", '', '61', '56|60', '70|90', 0);
        UpdateSequentialExecution(RoutingHeader."No.", '', '70', '61', '99', 10320);
        UpdateSequentialExecution(RoutingHeader."No.", '', '90', '61', '99', 780);
        UpdateSequentialExecution(RoutingHeader."No.", '', '99', '70|90', '', 120);

        // [GIVEN] Certiy Routing Version
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify();

        // [GIVEN] Item with Routing No. and without Production BOM
        ItemNo := CreateItemWithRoutingAndProductionBOM(RoutingHeader."No.", '');

        // [GIVEN] Create and refresh Released Production Order with due date current_year-05-11
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, ItemNo, 1);
        //ProductionOrder.Validate("Due Date", DMY2Date(11, 5, Date2DMY(WorkDate(), 3)));
        ProductionOrder.Validate("Due Date", WorkDate());
        ProductionOrder."Ending Date" :=
            LeadTimeMgt.GetPlannedEndingDate(
                ProductionOrder."Source No.", ProductionOrder."Location Code", '', ProductionOrder."Due Date", '', "Requisition Ref. Order Type"::"Prod. Order");
        ProductionOrder."Starting Date" := ProductionOrder."Ending Date";
        ProductionOrder."Starting Date-Time" := CreateDateTime(ProductionOrder."Starting Date", ProductionOrder."Starting Time");
        ProductionOrder."Ending Date-Time" := CreateDateTime(ProductionOrder."Ending Date", ProductionOrder."Ending Time");
        ProductionOrder.Modify();

        // [WHEN] Refersh Production Order backward
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [VERIFY] Verify: Posting specific Production Journal Line and changing due date for Production Order not raising any error
        PostProductionJournal(ProductionOrder."No.", '20');
        UpdateDueDateOnReleasedProductionOrder(ProductionOrder."No.", CalcDate('<' + Format(LibraryRandom.RandIntInRange(1, 3)) + 'D>', WorkDate()));
        PostProductionJournal(ProductionOrder."No.", '90');
        UpdateDueDateOnReleasedProductionOrder(ProductionOrder."No.", CalcDate('<' + Format(LibraryRandom.RandIntInRange(4, 6)) + 'D>', WorkDate()));
        PostProductionJournal(ProductionOrder."No.", '50');
        UpdateDueDateOnReleasedProductionOrder(ProductionOrder."No.", CalcDate('<' + Format(LibraryRandom.RandIntInRange(7, 9)) + 'D>', WorkDate()));
        PostProductionJournal(ProductionOrder."No.", '70');
        UpdateDueDateOnReleasedProductionOrder(ProductionOrder."No.", CalcDate('<' + Format(LibraryRandom.RandIntInRange(10, 12)) + 'D>', WorkDate()));
    end;

    [Test]
    procedure StartingDateTimeIsCorrectInProdOrderRoutingLinesWhenCreateRelProdOrderWithParallelRouting()
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: array[2] of Record "Prod. Order Routing Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: array[4] of Record "Work Center";
        ItemNo: Code[20];
        ShopCalendarCode: array[2] of Code[10];
    begin
        // [SCENARIO 550078] When Stan creates Released Production Order using an Item having Parallel Routing 
        // And runs Refresh Production Order action then Prod. Order Routing Lines are created with 
        // correct Starting Date Time based on Previous and Next Operations defined in that Parallel Routing.
        Initialize();

        // [GIVEN] Create a Capacity Unit of Measure in Minutes.
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, CapacityUnitOfMeasure.Type::Minutes);

        // [GIVEN] Create a ShopCalendar [1] with working days from 8AM till 4PM.
        ShopCalendarCode[1] := LibraryManufacturing.UpdateShopCalendarFullWorkingWeekCustomTime(080000T, 160000T);

        // [GIVEN] Create another ShopCalendar [2] with working days from 8AM till 11PM.
        ShopCalendarCode[2] := LibraryManufacturing.UpdateShopCalendarFullWorkingWeekCustomTime(080000T, 230000T);

        // [GIVEN] Create four Work Centers.
        CreateWorkCenterAndCalcWorkCenterCalendar(WorkCenter[1], 1.20, CapacityUnitOfMeasure.Code, LibraryRandom.RandIntInRange(3, 3), ShopCalendarCode[1]);
        CreateWorkCenterAndCalcWorkCenterCalendar(WorkCenter[2], 1.50, CapacityUnitOfMeasure.Code, LibraryRandom.RandInt(0), ShopCalendarCode[1]);
        CreateWorkCenterAndCalcWorkCenterCalendar(WorkCenter[3], 1.70, CapacityUnitOfMeasure.Code, LibraryRandom.RandInt(0), ShopCalendarCode[2]);
        CreateWorkCenterAndCalcWorkCenterCalendar(WorkCenter[4], 2.50, CapacityUnitOfMeasure.Code, LibraryRandom.RandInt(0), ShopCalendarCode[2]);

        // [GIVEN] Create a Routing with Type as Parallel.
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '100', RoutingLine.Type::"Work Center", WorkCenter[1]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '200', RoutingLine.Type::"Work Center", WorkCenter[2]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '300', RoutingLine.Type::"Work Center", WorkCenter[3]."No.");
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '400', RoutingLine.Type::"Work Center", WorkCenter[4]."No.");

        // [GIVEN] Update Next and Previous Operations in Routing Lines.
        UpdateSequentialExecution(RoutingHeader."No.", '', '100', '', '200|300', 0);
        UpdateSequentialExecution(RoutingHeader."No.", '', '200', '100', '400', LibraryRandom.RandIntInRange(100, 100));
        UpdateSequentialExecution(RoutingHeader."No.", '', '300', '100', '400', LibraryRandom.RandIntInRange(1000, 1000));
        UpdateSequentialExecution(RoutingHeader."No.", '', '400', '200|300', '', 0);

        // [GIVEN] Update Routing Status.
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [GIVEN] Create an Item with Routing.
        ItemNo := CreateItemWithRoutingAndProductionBOM(RoutingHeader."No.", '');

        // [GIVEN] Create a Released Production Order.
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder,
            "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item,
            ItemNo,
            LibraryRandom.RandInt(0));

        // [GIVEN] Refresh Production Order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Find Prod. Order Routing Line [1].
        ProdOrderRoutingLine[1].SetRange("Routing No.", RoutingHeader."No.");
        ProdOrderRoutingLine[1].SetRange("Operation No.", '100');
        ProdOrderRoutingLine[1].FindFirst();

        // [WHEN] Find Prod. Order Routing Line [2].
        ProdOrderRoutingLine[2].SetRange("Routing No.", RoutingHeader."No.");
        ProdOrderRoutingLine[2].SetRange("Operation No.", '200');
        ProdOrderRoutingLine[2].FindFirst();

        // [THEN] Starting Date-Time of Prod. Order Routing Line [1] is less then Starting Date-Time of Prod. Order Routing Line [2].
        Assert.IsTrue(ProdOrderRoutingLine[1]."Starting Date-Time" < ProdOrderRoutingLine[2]."Starting Date-Time", StartingDateTimeMustBeLessErr);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Manufacturing - Routings");
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Manufacturing - Routings");

        UpdateManufSetupSetNormalStartingEndingTime();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Manufacturing - Routings");
    end;

    local procedure CreateRtngHeaderWithMaxStrlen(var RoutingHeader: Record "Routing Header")
    begin
        RoutingHeader.Init();
        RoutingHeader.Validate("No.", CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(RoutingHeader."No.")), 1));
        RoutingHeader.Validate(Description, LibraryUtility.GenerateRandomXMLText(MaxStrLen(RoutingHeader.Description)));
        RoutingHeader.Insert(true);
    end;

    [Normal]
    local procedure CreateRtngPersonnelWithMaxStrlen(var RoutingPersonnel: Record "Routing Personnel"; RoutingHeader: Record "Routing Header")
    begin
        RoutingPersonnel.Init();
        RoutingPersonnel.Validate("Routing No.", RoutingHeader."No.");
        RoutingPersonnel."Operation No." := CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(RoutingPersonnel."Operation No.")), 1);
        RoutingPersonnel.Insert(true);
    end;

    local procedure CertifyRoutingAndRefreshLines(var RoutingHeader: Record "Routing Header"; var RoutingLine: array[6] of Record "Routing Line")
    var
        I: Integer;
    begin
        ChangeRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
        for I := 1 to ArrayLen(RoutingLine) do
            RoutingLine[I].Find();
    end;

    local procedure ChangeRoutingStatus(var RoutingHeader: Record "Routing Header"; NewStatus: Enum "Routing Status")
    begin
        RoutingHeader.Validate(Status, NewStatus);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateAndCertifyRoutingWithCrossOperations(NoOfOperations: Integer)
    var
        RoutingHeader: Record "Routing Header";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        CreateRoutingLinesSequence(RoutingHeader, NoOfOperations);
        ChangeRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateItemWithRouting(var Item: Record Item; RoutingNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure CreateRoutingLinesSequence(var RoutingHeader: Record "Routing Header"; NoOfRoutingBlocks: Integer)
    var
        WorkCenter: Record "Work Center";
        RoutingLine: array[4] of Record "Routing Line";
        PrevRoutingLine: Record "Routing Line";
        I: Integer;
        J: Integer;
    begin
        // To reproduce the performance bug, we need a "braided" routing consisting of blocks, 4 operations in each.
        // Each block has an entry and output operations, the other two in between are executed in parallel

        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        for I := 1 to NoOfRoutingBlocks do begin
            for J := 1 to 4 do
                LibraryManufacturing.CreateRoutingLine(
                  RoutingHeader, RoutingLine[J], '', Format(4 * I + J), RoutingLine[J].Type::"Work Center", WorkCenter."No.");

            // If there is a previous block, connect it with the next one
            if PrevRoutingLine."Operation No." <> '' then
                SetNextOperationNo(PrevRoutingLine, RoutingLine[1]."Operation No.");

            SetNextOperationNo(RoutingLine[1], StrSubstNo('%1|%2', RoutingLine[2]."Operation No.", RoutingLine[3]."Operation No."));
            SetNextOperationNo(RoutingLine[2], RoutingLine[4]."Operation No.");
            SetNextOperationNo(RoutingLine[3], RoutingLine[4]."Operation No.");

            PrevRoutingLine := RoutingLine[4];
        end;
    end;

    local procedure CreateRoutingWithBackwardFlushedWorkCenter(var RoutingHeader: Record "Routing Header")
    var
        WorkCenter: Record "Work Center";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        WorkCenter.Validate("Flushing Method", WorkCenter."Flushing Method"::Backward);
        WorkCenter.Modify(true);

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', Format(LibraryRandom.RandInt(10)), RoutingLine.Type::"Work Center", WorkCenter."No.");
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateWorkCenterWithCost(var WorkCenter: Record "Work Center"; UnitCost: Decimal; OverheadRate: Decimal)
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        WorkCenter.Validate("Unit Cost", UnitCost);
        WorkCenter.Validate("Overhead Rate", OverheadRate);
        WorkCenter.Modify(true);
    end;

    local procedure GetCodeCoverageForObject(ObjectType: Option; ObjectID: Integer; CodeLine: Text) NoOfHits: Integer
    var
        CodeCoverage: Record "Code Coverage";
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
    begin
        CodeCoverageMgt.Refresh();
        CodeCoverage.SetRange("Line Type", CodeCoverage."Line Type"::Code);
        CodeCoverage.SetRange("Object Type", ObjectType);
        CodeCoverage.SetRange("Object ID", ObjectID);
        CodeCoverage.SetFilter("No. of Hits", '>%1', 0);
        CodeCoverage.SetFilter(Line, '@*' + CodeLine + '*');
        if CodeCoverage.FindSet() then
            repeat
                NoOfHits += CodeCoverage."No. of Hits";
            until CodeCoverage.Next() = 0;
    end;

    local procedure MockRoutingHeader(var RoutingHeader: Record "Routing Header"; Status: Enum "Routing Status")
    begin
        RoutingHeader.Init();
        RoutingHeader."No." := LibraryUtility.GenerateGUID();
        RoutingHeader.Status := Status;
        RoutingHeader.Insert();
    end;

    local procedure MockRoutingVersion(var RoutingVersion: Record "Routing Version"; RoutingNo: Code[20]; Status: Enum "Routing Status")
    begin
        RoutingVersion.Init();
        RoutingVersion."Routing No." := RoutingNo;
        RoutingVersion."Version Code" := LibraryUtility.GenerateGUID();
        RoutingVersion.Status := Status;
        RoutingVersion.Insert();
    end;

    local procedure MockRoutingLine(var RoutingLine: Record "Routing Line"; RoutingNo: Code[20]; VersionCode: Code[20]; Type: Enum "Capacity Type Routing"; No: Code[20])
    begin
        RoutingLine.Init();
        RoutingLine."Routing No." := RoutingNo;
        RoutingLine."Version Code" := VersionCode;
        RoutingLine."Operation No." := LibraryUtility.GenerateGUID();
        RoutingLine.Type := Type;
        RoutingLine."No." := No;
        RoutingLine.Insert();
    end;

    local procedure MockRoutingLineOperationNo(var RoutingLine: Record "Routing Line"; RoutingNo: Code[20]; VersionCode: Code[20]; OperationNo: Code[10])
    begin
        RoutingLine.Init();
        RoutingLine."Routing No." := RoutingNo;
        RoutingLine."Version Code" := VersionCode;
        RoutingLine."Operation No." := OperationNo;
        RoutingLine.Insert();
    end;

    local procedure SetNextOperationNo(var RoutingLine: Record "Routing Line"; NextOperationNo: Code[30])
    begin
        RoutingLine.Validate("Next Operation No.", NextOperationNo);
        RoutingLine.Modify(true);
    end;

    local procedure UpdateManufSetupSetNormalStartingEndingTime()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        SetupUpdated: Boolean;
    begin
        ManufacturingSetup.Get();
        if ManufacturingSetup."Normal Starting Time" = 0T then begin
            ManufacturingSetup."Normal Starting Time" := 080000T;
            SetupUpdated := true;
        end;

        if ManufacturingSetup."Normal Ending Time" = 0T then begin
            ManufacturingSetup."Normal Ending Time" := 160000T;
            SetupUpdated := true;
        end;

        if SetupUpdated then
            ManufacturingSetup.Modify();
    end;

    local procedure CreateItemWithRoutingAndProductionBOM(RoutingNo: Code[20]; ProductionBOM: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Validate("Production BOM No.", ProductionBOM);
        Item.Validate("Routing No.", RoutingNo);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure UpdateSequentialExecution(RoutingNo: Code[20]; VersionCode: Code[20]; OperationNo: Code[10]; PreviousOperationNo: Code[30]; NextOperationNo: Code[30]; RunTime: Decimal)
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.Get(RoutingNo, VersionCode, OperationNo);
        RoutingLine.Validate("Previous Operation No.", PreviousOperationNo);
        RoutingLine.Validate("Next Operation No.", NextOperationNo);
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Modify();
    end;

    local procedure CreateWorkCenterWithCalendarForDAYS(var WorkCenter: Record "Work Center"; QueueTime: Decimal; UoMCode: Code[10]; QueueUoMCode: Code[10]; ShopCalendarCode: Code[10])
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Direct Unit Cost", 50);
        WorkCenter.Validate("Unit of Measure Code", UoMCode);
        WorkCenter.Validate(Capacity, 1);
        WorkCenter.Validate(Efficiency, 100);
        WorkCenter.Validate("Shop Calendar Code", ShopCalendarCode);
        WorkCenter.Validate("Queue Time", QueueTime);
        WorkCenter.Validate("Queue Time Unit of Meas. Code", QueueUoMCode);
        WorkCenter.Modify(true);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, DMY2Date(1, 1, Date2DMY(Today(), 3)), DMY2Date(31, 12, Date2DMY(Today(), 3)));
    end;

    procedure PostProductionJournal(ProdOrderNo: Code[20]; OperationNo: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Order No.", ProdOrderNo);
        ItemJournalLine.SetRange("Operation No.", OperationNo);
        if ItemJournalLine.FindFirst() then begin
            ItemJournalLine.Validate(Finished, true);
            ItemJournalLine.Modify(true);
            // Post Production Journal line
            CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);
        end;
    end;

    local procedure UpdateDueDateOnReleasedProductionOrder(ProdOrderNo: Code[20]; DueDate: Date)
    var
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.FILTER.SetFilter("No.", ProdOrderNo);
        ReleasedProductionOrder."Due Date".SetValue(DueDate);
        ReleasedProductionOrder.OK().Invoke();
    end;

    local procedure CreateWorkCenterAndCalcWorkCenterCalendar(
        var WorkCenter: Record "Work Center";
        UnitCost: Decimal;
        UOMCode: Code[10];
        Capacity: Decimal;
        ShopCalendarCode: Code[10])
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Direct Unit Cost", UnitCost);
        WorkCenter.Validate("Unit Cost", UnitCost);
        WorkCenter.Validate("Unit Cost Calculation", WorkCenter."Unit Cost Calculation"::Time);
        WorkCenter.Validate("Unit of Measure Code", UOMCode);
        WorkCenter.Validate(Capacity, Capacity);
        WorkCenter.Validate(Efficiency, LibraryRandom.RandIntInRange(100, 100));
        WorkCenter.Validate("Shop Calendar Code", ShopCalendarCode);
        WorkCenter.Validate("Queue Time", 0);
        WorkCenter.Validate("Queue Time Unit of Meas. Code", '');
        WorkCenter.Modify(true);

        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, DMY2Date(1, 1, Date2DMY(Today(), 3)), DMY2Date(31, 12, Date2DMY(Today(), 3)));
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            ItemTrackingMode::SetLotNo:
                begin
                    ItemTrackingLines.First();
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                    ItemTrackingLines.OK().Invoke();
                end;
            ItemTrackingMode::VerifyTotals:
                begin
                    ItemTrackingLines."SourceQuantityArray[1]".AssertEquals(LibraryVariableStorage.DequeueDecimal());
                    ItemTrackingLines.Quantity3.AssertEquals(LibraryVariableStorage.DequeueDecimal());
                end;
        end;
    end;

    [ModalPageHandler]
    procedure ProductionJournalModalPageHandler(var ProductionJournal: TestPage "Production Journal")
    var
        FlushingFilter: Enum "Flushing Method Filter";
        Qty: Decimal;
    begin
        Qty := LibraryVariableStorage.DequeueDecimal();

        ProductionJournal.FlushingFilter.SetValue(FlushingFilter::"All Methods");
        ProductionJournal.Last();
        ProductionJournal."Output Quantity".SetValue(Qty);

        LibraryVariableStorage.Enqueue(ItemTrackingMode::SetLotNo);
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(Qty);
        ProductionJournal.ItemTrackingLines.Invoke();

        ProductionJournal.Post.Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

