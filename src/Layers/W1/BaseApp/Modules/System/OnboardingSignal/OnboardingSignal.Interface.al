namespace System.Feedback;


interface "Onboarding Signal"
{
    Access = Public;

    /// <summary>
    /// Should check whether the onboarding criteria has been met.
    /// </summary>
    /// <returns> True if the onboarding criteria has been met. </returns>
    procedure IsOnboarded(): Boolean

}
