// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

enum 9190 Severity
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(1; Critical)
    {
    }
    value(2; Error)
    {
    }
    value(3; Warning)
    {
    }
    value(4; Information)
    {
    }
    value(5; Verbose)
    {
    }
    value(10; Hidden)
    {
    }
}