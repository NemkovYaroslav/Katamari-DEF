struct CurrentCameraData
{
    row_major matrix view;
    row_major matrix projection;
    row_major matrix sphereModel;
    float3           position;
    float3           spherePosition;
};
cbuffer CameraConstantBuffer : register(b0)
{
    CurrentCameraData curCamera;
};

struct VS_IN
{
    float4 pos : POSITION0;
};

struct PS_IN
{
    float4 pos : SV_POSITION;
};

PS_IN VSMain(VS_IN input)
{
    PS_IN output = (PS_IN) 0; 
    output.pos   = mul(mul(mul(float4(input.pos.xyz, 1.0f), curCamera.sphereModel), curCamera.view), curCamera.projection);  
    return output;
}

Texture2D DiffuseMap  : register(t0);
Texture2D NormalMap   : register(t1); ///
Texture2D WorldPosMap : register(t2); ///

struct GBufferData
{
    float4 DiffuseSpec;
    float3 Normal;
    float3 WorldPos;
};

GBufferData ReadGBuffer(float2 screenPos)
{
    GBufferData buf = (GBufferData) 0;
    
    buf.DiffuseSpec = DiffuseMap.Load(float3(screenPos, 0));
    buf.WorldPos    = WorldPosMap.Load(float3(screenPos, 0)).xyz;
    buf.Normal      = NormalMap.Load(float3(screenPos, 0)).xyz;
    
    return buf;
}

float4 PSMain(PS_IN input) : SV_Target
{
    GBufferData gBuffer = ReadGBuffer(input.pos.xy);
    
    float3 diffValue = gBuffer.DiffuseSpec;
    
    float distance = length(curCamera.spherePosition - gBuffer.WorldPos.xyz);
    float attenuation = 1.0f / (1.0f + 0.09f * distance + 0.032 * (distance * distance));
    
    return float4(float3(1.0f, 0.0f, 0.0f), 1.0f);
}