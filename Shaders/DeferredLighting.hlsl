cbuffer CameraConstantBuffer : register(b0)
{
    row_major matrix view;
    row_major matrix projection;
    row_major matrix model;
    float3 cameraPosition;
};

struct RemLight
{
    float3 direction;
    float3 ambient;
    float3 diffuse;
    float3 specular;
};
cbuffer LightConstantBuffer : register(b1)
{
    RemLight remLight;
};

cbuffer LightCameraConstantBuffer : register(b2)
{
    row_major matrix ViewProj[4];
    float4 Distances;
};

struct VS_IN
{
    float4 pos : POSITION0;
};

struct PS_IN
{
    float4 pos : SV_POSITION;
};

PS_IN VSMain(uint id : SV_VertexID)
{
    PS_IN output = (PS_IN) 0;
    
    float2 inds = float2(id & 1, (id & 2) >> 1);
    output.pos = float4(inds * float2(2, -2) + float2(-1, 1), 0, 1);
    
    return output;
}

Texture2D DiffuseMap : register(t0);
Texture2D NormalMap : register(t1); ///
Texture2D EmissiveMap : register(t2); ///
Texture2D WorldPosMap : register(t3); ///

Texture2DArray ShadowMap : register(t4);
SamplerComparisonState ShadowMapSampler : register(s0);

struct GBufferData
{
    float4 DiffuseSpec;
    float3 Normal;
    float3 Emissive;
    float3 WorldPos;
};

GBufferData ReadGBuffer(float2 screenPos)
{
    GBufferData buf = (GBufferData) 0;
    
    buf.DiffuseSpec = DiffuseMap.Load(float3(screenPos, 0));
    buf.WorldPos = WorldPosMap.Load(float3(screenPos, 0)).xyz;
    buf.Emissive = EmissiveMap.Load(float3(screenPos, 0)).xyz;
    buf.Normal = NormalMap.Load(float3(screenPos, 0)).xyz;
    
    return buf;
}

float3 CalcDirLight(RemLight remLight, float3 normal, float3 viewDir, GBufferData gBuffer, float4 posViewProj, float layer);

float4 PSMain(PS_IN input) : SV_Target
{
    GBufferData gBuffer = ReadGBuffer(input.pos.xy);
    
    float3 norm = normalize(gBuffer.Normal);
    float3 viewDir = normalize(cameraPosition - gBuffer.WorldPos.xyz);
    
    float4 cameraViewPosition = mul(float4(gBuffer.WorldPos.xyz, 1.0f), view);
    
    float layer = 3.0f;
    float depthVal = abs(cameraViewPosition.z);
    for (int i = 0; i < 4; ++i)
    {
        if (depthVal < Distances[i])
        {
            layer = (float) i;
            break;
        }
    }
    
    float4 posViewProj = mul(float4(gBuffer.WorldPos, 1.0f), ViewProj[layer]);
    
    float3 result = CalcDirLight(remLight, norm, viewDir, gBuffer, posViewProj, layer);

    return float4(result, 1.0f);
}

float IsLighted(float3 lightDir, float3 normal, float4 posViewProj, float layer);

float3 CalcDirLight(RemLight remLight, float3 normal, float3 viewDir, GBufferData gBuffer, float4 posViewProj, float layer)
{
    float3 diffValue = gBuffer.DiffuseSpec;
    float3 lightDir = normalize(-remLight.direction);
    float diff = max(dot(normal, lightDir), 0.0);
    float3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 128);
    float3 ambient = remLight.ambient * diffValue;
    float3 diffuse = remLight.diffuse * diff * diffValue;
    float3 specular = remLight.specular * spec * diffValue;
    
    float1 isLighted = 1;
    
    isLighted = IsLighted(lightDir, normal, posViewProj, layer);
    
    return (gBuffer.Emissive + ambient + (diffuse + specular) * isLighted);
}

float IsLighted(float3 lightDir, float3 normal, float4 posViewProj, float layer)
{
    float ndotl = dot(normal, lightDir);
    float bias = clamp(0.005f * (1.0f - ndotl), 0.0f, 0.0005f);
    
    float3 projectTexCoord;

    projectTexCoord.x = posViewProj.x / posViewProj.w;
    projectTexCoord.y = posViewProj.y / posViewProj.w;
    projectTexCoord.z = posViewProj.z / posViewProj.w;

    projectTexCoord.x = projectTexCoord.x * 0.5 + 0.5f;
    projectTexCoord.y = projectTexCoord.y * -0.5 + 0.5f;
    
    float max_depth = ShadowMap.SampleCmpLevelZero(ShadowMapSampler, float3(projectTexCoord.x, projectTexCoord.y, layer), projectTexCoord.z);

    float currentDepth = (posViewProj.z / posViewProj.w);

    currentDepth = currentDepth - bias;
    
    if (max_depth < currentDepth)
    {
        return 0;
    }
    return max_depth;
}