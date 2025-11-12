#if not CLEAN25 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.FieldService;

enum 6402 "FS Work Order Line Synch. Rule"
{
    AssignmentCompatibility = true;
    Extensible = true;
    ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
    ObsoleteState = Pending;
    ObsoleteTag = '25.0';

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