struct CurrentCameraData
{
    row_major matrix view;
    row_major matrix projection;
    row_major matrix model;
    float3           position;
};
cbuffer CameraConstantBuffer : register(b0)
{
    CurrentCameraData curCamera;
};

struct MaterialData
{
    float3 ambient;
    float3 diffuse;
    float3 specular;
};
struct PointLightData
{
    float3 lightColor;
    float4 valueConLinQuadCount;
    float3 position;
};
cbuffer LightConstantBuffer : register(b1)
{
    MaterialData   material;
    PointLightData poiLight;
};

struct VS_IN
{
    float4 pos : POSITION0;
};

struct PS_IN
{
    float4 pos      : SV_POSITION;
    float4 modelPos : POSITION;
};

PS_IN VSMain(VS_IN input)
{
    PS_IN output = (PS_IN) 0; 
    output.pos = mul(mul(mul(float4(input.pos.xyz, 1.0f), curCamera.model), curCamera.view), curCamera.projection);
    
    float4 modelPos = mul(float4(input.pos.xyz, 1.0f), curCamera.model);  
    output.modelPos = modelPos;
    
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
    buf.WorldPos = WorldPosMap.Load(float3(screenPos, 0)).xyz;
    buf.Normal = NormalMap.Load(float3(screenPos, 0)).xyz;
    
    return buf;
}

float3 CalcDirLight(float4 modelPos, GBufferData gBuffer);

float4 PSMain(PS_IN input) : SV_Target
{
    GBufferData gBuffer = ReadGBuffer(input.pos.xy);  
    float3 result = CalcDirLight(input.modelPos, gBuffer);
    return float4(result, 1.0f);
}

float3 CalcDirLight(float4 modelPos, GBufferData gBuffer)
{
    float3 diffValue = gBuffer.DiffuseSpec;
    
    //POINT LIGHT
    float distance     = length(poiLight.position - modelPos.xyz);
    float  attenuation = 1.0f / (poiLight.valueConLinQuadCount.x + poiLight.valueConLinQuadCount.y * distance + poiLight.valueConLinQuadCount.z * (distance * distance));

    float3 diffuse  = material.diffuse  * diffValue * attenuation * poiLight.lightColor;
    float3 specular = material.specular * diffValue * attenuation * poiLight.lightColor;
    
    return (diffuse + specular);
}