#if not CLEAN25
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.FieldService;

enum 6401 "FS Work Order Line Post Rule"
{
    AssignmentCompatibility = true;
    Extensible = true;
    ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
    ObsoleteState = Pending;
    ObsoleteTag = '25.0';

    value(0; Never)
    {
        Caption = 'I will post project journal lines manually';
    }
    value(1; LineUsed)
    {
        Caption = 'when work order product/service is used';
    }
    value(2; WorkOrderCompleted)
    {
        Caption = 'when work order is completed';
    }
}
#endif