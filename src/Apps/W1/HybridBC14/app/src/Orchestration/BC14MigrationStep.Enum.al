// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;


enum 46882 "BC14 Migration Step"
{
    Extensible = false;

    value(0; NotStarted)
    {
        Caption = 'Not Started';
    }
    value(1; Setup)
    {
        Caption = 'Setup Data';
    }
    value(2; Master)
    {
        Caption = 'Master Data';
    }
    value(3; Transaction)
    {
        Caption = 'Transactional Data';
    }
    value(4; Historical)
    {
        Caption = 'Historical Data';
    }
    value(5; Posting)
    {
        Caption = 'Journal Posting';
    }
    value(6; Completed)
    {
        Caption = 'Completed';
    }
}
