// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

/// <summary>
/// The status of the function response.
/// </summary>
enum 7777 "AOAI Function Response Status"
{
    Access = Public;
    Extensible = false;

    /// <summary>
    /// The function has not been invoked.
    /// </summary>
    value(0; "Not Invoked")
    {
        Caption = 'Not Invoked';
    }

    /// <summary>
    /// The function was invoked and completed without error.
    /// </summary>
    value(1; "Invoke Success")
    {
        Caption = 'Invoke Success';
    }

    /// <summary>
    /// The function was invoked and completed with error.
    /// </summary>
    value(2; "Invoke Error")
    {
        Caption = 'Invoke Error';
    }

    /// <summary>
    /// The requested function could not be found.
    /// </summary>
    value(3; "Function Not Found")
    {
        Caption = 'Function Not Found';
    }

    /// <summary>
    /// The requested function was invalid.
    /// </summary>
    value(4; "Function Invalid")
    {
        Caption = 'Function Invalid';
    }
}