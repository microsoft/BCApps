// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.API;

using Microsoft.QualityManagement.Document;

/// <summary>
/// Do not use this query outside of web services.
/// Power automate friendly web service for quality inspections.
/// This web service is used to help list test values.
/// </summary>
query 20401 "Qlty. Inspection Test Values"
{
    QueryType = API;
    Caption = 'Quality Inspection Test Values', Locked = true;
    APIPublisher = 'microsoft';
    APIGroup = 'qualityInspection';
    APIVersion = 'v1.0';
    EntityName = 'qualityInspectionTestValue';
    EntityCaption = 'Quality Inspection Test Value';
    EntitySetName = 'qualityInspectionTestValues';
    EntitySetCaption = 'Quality Inspection Test Values';
    DataAccessIntent = ReadOnly;
    OrderBy = ascending(lineSystemModifiedAt);

    elements
    {
        dataitem(QltyInspectionTestHeader; "Qlty. Inspection Test Header")
        {
            column(systemId; SystemId) { }
            column(templateCode; "Template Code") { }
            column(testNo; "No.") { }
            column(retestNo; "Retest No.") { }
            column(testStatus; Status)
            {
                Caption = 'testStatus', Locked = true;
            }
            column(systemCreatedBy; SystemCreatedBy) { }
            column(systemCreatedAt; SystemCreatedAt) { }
            column(finishedByUserID; "Finished By User ID") { }
            column(finishedAtDate; "Finished Date") { }
            column(finishedAtDay; "Finished Date")
            {
                Method = Day;
            }
            column(finishedAtMonth; "Finished Date")
            {
                Method = Month;
            }
            column(finishedAtYear; "Finished Date")
            {
                Method = Year;
            }
            column(gradeCode; "Grade Code") { }
            column(gradeDescription; "Grade Description") { }
            column(sourceItemNo; "Source Item No.") { }
            column(sourceVariantCode; "Source Variant Code") { }
            column(sourceLotNo; "Source Lot No.") { }
            column(sourceSerialNo; "Source Serial No.") { }
            column(sourcePackageNo; "Source Package No.") { }
            column(sourceDocumentNo; "Source Document No.") { }
            column(sourceDocumentLineNo; "Source Document Line No.") { }
            column(sourceTaskNo; "Source Task No.") { }
            column(sourceQuantityBase; "Source Quantity (Base)") { }
            column(sourceRecordTableNo; "Source Record Table No.") { }
            column(sourceRecordId; "Source RecordId") { }
            column(sourceRecordId2; "Source RecordId 2") { }
            column(sourceRecordId3; "Source RecordId 3") { }
            column(sourceCustom1; "Source Custom 1") { }
            column(sourceCustom2; "Source Custom 2") { }
            column(sourceCustom3; "Source Custom 3") { }
            column(sourceCustom4; "Source Custom 4") { }
            column(sourceCustom5; "Source Custom 5") { }
            column(sourceCustom6; "Source Custom 6") { }
            column(sourceCustom7; "Source Custom 7") { }
            column(sourceCustom8; "Source Custom 8") { }
            column(sourceCustom9; "Source Custom 9") { }
            column(sourceCustom10; "Source Custom 10") { }

            dataitem(QltyInspectionTestLine; "Qlty. Inspection Test Line")
            {
                DataItemLink = "Test No." = QltyInspectionTestHeader."No.", "Retest No." = QltyInspectionTestHeader."Retest No.";

                column(lineSystemId; SystemId) { }
                column(lineNo; "Line No.") { }
                column(lineFieldCode; "Field Code") { }
                column(lineFieldType; "Field Type")
                {
                    Caption = 'lineFieldType', Locked = true;
                }
                column(lineGradeCode; "Grade Code") { }
                column(lineNumericValue; "Numeric Value") { }
                column(lineTestValue; "Test Value") { }
                column(lineSystemModifiedBy; SystemModifiedBy) { }
                column(lineSystemModifiedAt; SystemModifiedAt) { }
                column(lineSystemModifiedAtDay; SystemModifiedAt)
                {
                    Method = Day;
                }
                column(lineSystemModifiedAtMonth; SystemModifiedAt)
                {
                    Method = Month;
                }
                column(lineSystemModifiedAtYear; SystemModifiedAt)
                {
                    Method = Year;
                }
            }
        }
    }
}
