cbuffer CameraConstantBuffer : register(b0)
{
    row_major matrix viewProjection;
    row_major matrix model;
    float3 cameraPosition;
};

struct DirLight
{
    float3 direction;
    float3 ambient;
    float3 diffuse;
    float3 specular;
};

cbuffer LightConstantBuffer : register(b1)
{
	DirLight dirLight;
};

struct VS_IN
{
    float3 pos : POSITION0;
    float2 tex : TEXCOORD0;
    float4 normal : NORMAL0;
};

struct PS_IN
{
    float4 pos : SV_POSITION;
    float2 tex : TEXCOORD;
    float4 normal : NORMAL;
    float3 modelPos : POSITION;
};

PS_IN VSMain(VS_IN input)
{
    PS_IN output;

    float4 pos = float4(input.pos, 1.0f);
    float4 modelPos = mul(pos, model);
    output.pos = mul(modelPos, viewProjection);
    output.normal = mul(transpose(model), input.normal);
    output.tex = input.tex;
    output.modelPos = modelPos.xyz;
    
    return output;
}

Texture2D DiffuseMap;
SamplerState Sampler;

float3 CalcDirLight(DirLight light, float3 normal, float3 viewDir, float2 uv);

float4 PSMain(PS_IN input) : SV_Target
{
    //float3 norm = normalize(input.normal);
    //float3 viewDir = normalize(cameraPosition - input.modelPos);

    //float3 result = CalcDirLight(dirLight, norm, viewDir, input.tex);

    //return float4(result, 1.0f);
    
    return DiffuseMap.SampleLevel(Sampler, input.tex.xy, 0);
}

float3 CalcDirLight(DirLight light, float3 normal, float3 viewDir, float2 uv)
{
    float3 lightDir = normalize(-light.direction);

    float diff = max(dot(normal, lightDir), 0.0);

    float3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 5);

    float3 ambient  = light.ambient         * DiffuseMap.Sample(Sampler, uv).rgb;
    float3 diffuse  = light.diffuse  * diff * DiffuseMap.Sample(Sampler, uv).rgb;
    float3 specular = light.specular * spec * DiffuseMap.Sample(Sampler, uv).rgb;

    return (ambient + diffuse + specular);
}