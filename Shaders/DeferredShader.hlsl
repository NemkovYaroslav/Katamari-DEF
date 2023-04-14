cbuffer CameraConstantBuffer : register(b0)
{
    row_major matrix view;
    row_major matrix projection;
    row_major matrix model;
    float3 cameraPosition;
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
    float4 modelPos : POSITION;
    float4 normal : NORMAL;
    float2 tex : TEXCOORD;
};

Texture2D DiffuseMap : register(t0);
SamplerState Sampler : register(s0);

PS_IN VSMain(VS_IN input)
{
    PS_IN output = (PS_IN) 0;
 
    float4 modelPos = mul(float4(input.pos, 1.0f), model);
    output.pos = mul(mul(modelPos, view), projection);
    output.modelPos = modelPos;
    output.normal = mul(transpose(model), input.normal);
    output.tex = input.tex;
    
    return output;
}

struct PSOutput
{
    float4 Diffuse : SV_Target0;
    float4 Normal : SV_Target1;
    float4 Emissive : SV_Target2;
    float4 WorldPos : SV_Target3;
};

[earlydepthstencil]
PSOutput PSMain(PS_IN input)
{
    PSOutput ret = (PSOutput) 0;
    
    ret.Diffuse.rgb = DiffuseMap.Sample(Sampler, input.tex).rgb;
    ret.WorldPos = input.modelPos;
    //ret.Diffuse.a = float3(1, 1, 1);
    ret.Emissive = float4(0.0f, 0.0f, 0.0f, 0.0f);
    
    float3 normal = input.normal;
    float3 unpackedNormal = normalize(normal * 2.0f - 1.0f);
    ret.Normal = float4(unpackedNormal, 0);
    
    return ret;
}