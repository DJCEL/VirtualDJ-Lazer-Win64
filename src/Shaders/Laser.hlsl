////////////////////////////////
// File: Laser.hlsl
////////////////////////////////

//--------------------------------------------------------------------------------------
// Textures and Samplers
//--------------------------------------------------------------------------------------
Texture2D g_Texture2D : register(t0);
SamplerState g_SamplerState : register(s0);

//--------------------------------------------------------------------------------------
// Constant Buffer
//--------------------------------------------------------------------------------------
cbuffer PS_CONSTANTBUFFER : register(b0)
{
    float g_FX_Time;
    float g_FX_SongPosBeats;
    float g_FX_Width;
    float g_FX_Height;
    float g_FX_Beats_on;
};

//--------------------------------------------------------------------------------------
// Input structure
//--------------------------------------------------------------------------------------
struct PS_INPUT
{
	float4 Position : SV_Position;
	float4 Color : COLOR0;
	float2 TexCoord : TEXCOORD0;
};

//--------------------------------------------------------------------------------------
// Output structure
//--------------------------------------------------------------------------------------
struct PS_OUTPUT
{
    float4 Color : SV_TARGET;
};
//--------------------------------------------------------------------------------------
// Additional Functions
//--------------------------------------------------------------------------------------
float hash(float2 p)
{
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5454);
}
//--------------------------------------------------------------------------------------
float noise(float2 p)
{
    float2 i = floor(p);
    float2 f = frac(p);
   
    float a = hash(i);
    float b = hash(i + float2(1, 0));
    float c = hash(i + float2(0, 1));
    float d = hash(i + float2(1, 1));
    
    float2 u = f * f * (3.0 - 2.0 * f);
    
    return lerp(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}
//--------------------------------------------------------------------------------------
// Improved beam function with better distance calculation
float getBeam(float2 p, float angle, float thickness)
{
    float a = atan2(p.y, p.x);
    float d = abs(a - angle);

    const float TWO_PI = 6.28318530718;

    // Wrap angle difference to shortest path
    d = min(d, TWO_PI - d);

    // Smooth step for soft beam edges
    return smoothstep(thickness, 0.0, d);
}
//--------------------------------------------------------------------------------------
// Glow function with configurable falloff
float calculateGlow(float distance, float glowIntensity, float falloffPower)
{
    // Use power function for more natural glow falloff
    return exp(-distance * falloffPower) * glowIntensity;
}
//--------------------------------------------------------------------------------------
float3 laser1(float2 texcoord, float time)
{
    //--- Shader Parameters ---
    int beamCount = 24; // Number of laser beams
    float spread = 3.14; // Angular spread (radians)
    float thickness = 0.01; // Base beam thickness
    float glowIntensity = 4.0; // Glow intensity
    float glowFalloff = 2.0; // Glow falloff power (higher = sharper)
    float noiseAmount = 0.01;
    
    if (beamCount <= 1) beamCount = 2;

    //--- Texture Coordinates ---
    float2 origin = float2(0.5f, 0.5f);
    float2 p = texcoord - origin;
    float dist = length(p);

    // Rotate coordinates for animation
    p = float2(-p.y, p.x);
        

    //--- Accumulate Beam Colors ---
    float3 col = float3(0.0, 0.0, 0.0);

    float j = 0.0f;
    float angle = 0.0f;
    float beam = 0.0f;
    float glow = 0.0f;
    float intensity = 0.0f;
    float3 beamColor = float3(0.0, 1.0, 0.0); // Green laser color
    
    for (int i = 0;i <beamCount; i++)
    {
        j = (float)i / (beamCount - 1);
        
        // Apply rotation to spread
        angle = lerp(-spread * 0.5, spread * 0.5, j);
        
        // Calculate beam contribution
        beam = getBeam(p, angle, thickness);
        
        glow = exp(-dist * glowFalloff) * glowIntensity;;

        // Combine beam and glow
        intensity = beam * glow;
        
        // Accumulate color
        col += intensity * beamColor;
    }
    
    // Strong central core (white-hot)
    float core = exp(-dist * 30.0);
    col += core * float3(0.3, 1.0, 0.2) * 1.0;

    // fade to black background
    float intensity2 = max(col.r, max(col.g, col.b));
    col *= smoothstep(0.01, 0.1, intensity2);
    
    return col;
}
//--------------------------------------------------------------------------------------
// Pixel Shader
//--------------------------------------------------------------------------------------
PS_OUTPUT ps_main(PS_INPUT input)
{
    float time = (g_FX_Beats_on == 1.0f) ? g_FX_SongPosBeats : g_FX_Time;
    float iTime = g_FX_Time;
    float2 texcoord = input.TexCoord;
    
    // Laser effect
    float3 col = laser1(texcoord, time);
   
    float4 color = float4(col, 1.0);
    
    // Final output with input color modulation
    PS_OUTPUT output;
    output.Color = color * input.Color;
    return output;
}