// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

#pragma warning disable AL0659 // Accepted: renaming the enum is a breaking change
enum 11035 "Intrastat Submission Channel DE"
#pragma warning restore AL0659
{
    Extensible = true;
    Caption = 'Intrastat Submission Channel';

    value(0; IDEV)
    {
        Caption = 'IDEV';
    }
    value(1; eStatistikCore)
    {
        Caption = 'eSTATISTIK.CORE';
    }
}
