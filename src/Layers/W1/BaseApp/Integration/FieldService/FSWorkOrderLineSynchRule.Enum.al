#if not CLEANSCHEMA31
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.FieldService;

enum 6402 "FS Work Order Line Synch. Rule"
{
    AssignmentCompatibility = true;
    Extensible = true;
#if CLEANSCHEMA28 // marking obsolete when the table is removed, deleting min. 1 version later
    ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
    ObsoleteState = Pending;
    ObsoleteTag = '31.0';
#endif

    value(0; LineUsed)
    {
        Caption = 'when work order product/service is used';
    }
    value(1; WorkOrderCompleted)
    {
        Caption = 'when work order is completed';
    }
}
#endif