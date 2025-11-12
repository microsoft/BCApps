// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

interface "Reminder Action"
{
    procedure Initialize(ReminderActionSystemId: Guid);
    procedure GetSetupRecord(var TableID: Integer; var RecordSystemId: Guid);
    procedure GetReminderActionSystemId(): Guid;
    procedure GetID(): Code[50];
    procedure GetSummary(): Text;
    procedure CreateNew(ActionCode: Code[50]; ActionGroupCode: Code[50]): Boolean;
    procedure Setup();
    procedure Delete();
    procedure Invoke(var ErrorOccured: Boolean);
    procedure ValidateSetup();
}