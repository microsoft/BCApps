// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

interface "AOAI Function"
{
    Access = Public;

    /// <summary>
    /// Get the prompt for the Function. Function prompt object describes the Function and the should contain the following fields:
    ///     - Type: The name of the Function, currently only function type is supported. For functions following fields are allowed:
    ///     -- Name: The name of the Function. (Required)
    ///     -- Description: The description of the Function. (Optional)
    ///     -- Parameters: The parameters of the Function. (Required)
    /// More details can be found here: https://go.microsoft.com/fwlink/?linkid=2254538
    /// </summary>
    procedure GetPrompt(): JsonObject;

    /// <summary>
    /// This function is invoked as a response from Azure Open AI.
    ///  -Arguments: The expected parameters of the Function defined.
    /// The function returns a variant, and it's up to the implementation to decide what to return.
    /// </summary>
    procedure Execute(Arguments: JsonObject): Variant;

    /// <summary>
    /// Get the name of the function.
    /// </summary>
    /// <remarks>This needs to match the function name in GetPrompt.</remarks>
    procedure GetName(): Text;
}