struct CurrentCameraData
{
    row_major matrix view;
    row_major matrix projection;
    float3           position;
};
cbuffer CameraConstantBuffer : register(b0)
{
    CurrentCameraData curCamera;
};

struct PointLightData
{
    row_major matrix model;
    float3           lightColor;
    float4           constLinearQuadCount;
    float3           position;
};
cbuffer LightConstantBuffer : register(b1)
{
    PointLightData poiLight;
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
    output.pos   = mul(mul(mul(float4(input.pos.xyz, 1.0f), poiLight.model), curCamera.view), curCamera.projection);  
    return output;
}

Texture2D DiffuseMap  : register(t0);
Texture2D NormalMap   : register(t1);
Texture2D WorldPosMap : register(t2);

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

    ///*
    float3 diffValue = gBuffer.DiffuseSpec.rgb;
    float3 normal    = gBuffer.Normal;
    float3 viewDir   = normalize(curCamera.position - gBuffer.WorldPos);
    
    float3 lightDir   = normalize(poiLight.position - gBuffer.WorldPos);
    float diff        = max(dot(normal, lightDir), 0.0f);
    float3 reflectDir = reflect(-lightDir, normal);
    float  spec       = pow(max(dot(viewDir, reflectDir), 0.0f), 128);
    
    float  distance   = length(poiLight.position - gBuffer.WorldPos);
    float attenuation = 1.0f / (poiLight.constLinearQuadCount.x + poiLight.constLinearQuadCount.y * distance + poiLight.constLinearQuadCount.z * (distance * distance));
    float3 diffuse    = attenuation * float3(1.0f, 0.0f, 0.0f) * diffValue * diff;
    float3 specular   = attenuation * float3(1.0f, 0.0f, 0.0f) * diffValue * spec;

    return float4(float3(diffuse + specular), 0.0f);
    //*/

    //return float4(float3(1.0f, 0.0f, 0.0f), 0.0f);
}