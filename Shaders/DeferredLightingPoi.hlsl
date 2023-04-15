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
    MaterialData material;
    PointLightData poiLight[2];
};
struct ShadowData
{
    row_major matrix viewProj[4];
    float4 distances;
};
cbuffer LightCameraConstantBuffer : register(b2)
{
    ShadowData shadow;
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

float3 CalcDirLight(float3 normal, float3 viewDir, GBufferData gBuffer, float4 posViewProj, float layer);

float4 PSMain(PS_IN input) : SV_Target
{
    GBufferData gBuffer = ReadGBuffer(input.pos.xy);
    
    float3 normal = normalize(gBuffer.Normal);
    float3 viewDir = normalize(curCamera.position - gBuffer.WorldPos.xyz);
    
    float4 cameraViewPosition = mul(float4(gBuffer.WorldPos.xyz, 1.0f), curCamera.view);
    
    float layer = 3.0f;
    float depthVal = abs(cameraViewPosition.z);
    for (int i = 0; i < 4; ++i)
    {
        if (depthVal < shadow.distances[i])
        {
            layer = (float) i;
            break;
        }
    }
    
    float4 dirLightViewProj = mul(float4(gBuffer.WorldPos.xyz, 1.0f), shadow.viewProj[layer]);
    
    float3 result = CalcDirLight(normal, viewDir, gBuffer, dirLightViewProj, layer);

    return float4(result, 1.0f);
}

float IsLighted(float3 lightDir, float3 normal, float4 dirLightViewProj, float layer);

float3 CalcDirLight(float3 normal, float3 viewDir, GBufferData gBuffer, float4 posViewProj, float layer)
{
    float3 diffValue = gBuffer.DiffuseSpec;   
    //POINT LIGHT
    float3 ambient  = material.ambient  * diffValue;
    float3 diffuse  = material.diffuse  * diffValue;
    float3 specular = material.specular * diffValue;  
    for (int i = 0; i < poiLight[i].valueConLinQuadCount.w; i++)
    {
        float distance = length(poiLight[i].position - gBuffer.WorldPos.xyz);
        float attenuation = 1.0f / (poiLight[i].valueConLinQuadCount.x + poiLight[i].valueConLinQuadCount.y * distance + poiLight[i].valueConLinQuadCount.z * (distance * distance));
        ambient  += ambient  * attenuation * poiLight[i].lightColor;
        diffuse  += diffuse  * attenuation * poiLight[i].lightColor;
        specular += specular * attenuation * poiLight[i].lightColor;
    } 
    return (ambient + diffuse + specular);
}