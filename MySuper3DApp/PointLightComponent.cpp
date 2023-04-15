#include "PointLightComponent.h"
#include "GameObject.h"
#include "Game.h"
#include "RenderSystem.h"
#include "DisplayWin32.h"
#include "CameraComponent.h"
#include "GBuffer.h"

struct alignas(16) CameraData
{
	Matrix  camView;
	Matrix  camProjection;
	Matrix  objModel;
	Vector3 camPosition;
	Vector3 objPosition;
};

PointLightComponent::PointLightComponent(float constant, float linear, float quadratic)
{
	this->constant  = constant;
	this->linear    = linear;
	this->quadratic = quadratic;
}

void PointLightComponent::Initialize()
{
	D3D11_BUFFER_DESC vertexBufDesc = {};
	vertexBufDesc.Usage = D3D11_USAGE_DEFAULT;
	vertexBufDesc.BindFlags = D3D11_BIND_VERTEX_BUFFER;
	vertexBufDesc.CPUAccessFlags = 0;
	vertexBufDesc.MiscFlags = 0;
	vertexBufDesc.StructureByteStride = 0;
	vertexBufDesc.ByteWidth = sizeof(DirectX::XMFLOAT4) * std::size(poiPoints);
	D3D11_SUBRESOURCE_DATA vertexData = {};
	vertexData.pSysMem = poiPoints.data();
	vertexData.SysMemPitch = 0;
	vertexData.SysMemSlicePitch = 0;
	auto result = Game::GetInstance()->GetRenderSystem()->device->CreateBuffer(&vertexBufDesc, &vertexData, poiVertexBuffer.GetAddressOf());
	assert(SUCCEEDED(result));

	D3D11_BUFFER_DESC indexBufDesc = {};
	indexBufDesc.Usage = D3D11_USAGE_DEFAULT;
	indexBufDesc.BindFlags = D3D11_BIND_INDEX_BUFFER;
	indexBufDesc.CPUAccessFlags = 0;
	indexBufDesc.MiscFlags = 0;
	indexBufDesc.StructureByteStride = 0;
	indexBufDesc.ByteWidth = sizeof(int) * std::size(poiIndices);
	D3D11_SUBRESOURCE_DATA indexData = {};
	indexData.pSysMem = poiIndices.data();
	indexData.SysMemPitch = 0;
	indexData.SysMemSlicePitch = 0;
	result = Game::GetInstance()->GetRenderSystem()->device->CreateBuffer(&indexBufDesc, &indexData, poiIndexBuffer.GetAddressOf());
	assert(SUCCEEDED(result));
	
	std::cout << "!!!!!!!!!!!!!!!!" << std::endl;

	constBuffer = new ID3D11Buffer * [3];

	D3D11_BUFFER_DESC firstConstBufferDesc = {};
	firstConstBufferDesc.Usage = D3D11_USAGE_DYNAMIC;
	firstConstBufferDesc.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
	firstConstBufferDesc.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
	firstConstBufferDesc.MiscFlags = 0;
	firstConstBufferDesc.StructureByteStride = 0;
	firstConstBufferDesc.ByteWidth = sizeof(CameraData);
	result = Game::GetInstance()->GetRenderSystem()->device->CreateBuffer(&firstConstBufferDesc, nullptr, &constBuffer[0]);
	assert(SUCCEEDED(result));
}

void PointLightComponent::Draw()
{
	const CameraData cameraData
	{
		Game::GetInstance()->currentCamera->gameObject->transformComponent->GetView(),
		Game::GetInstance()->currentCamera->GetProjection(),
		gameObject->transformComponent->GetModel(),
		Game::GetInstance()->currentCamera->gameObject->transformComponent->GetPosition(),
		gameObject->transformComponent->GetPosition()
	};
	D3D11_MAPPED_SUBRESOURCE firstMappedResource;
	Game::GetInstance()->GetRenderSystem()->context->Map(constBuffer[0], 0, D3D11_MAP_WRITE_DISCARD, 0, &firstMappedResource);
	memcpy(firstMappedResource.pData, &cameraData, sizeof(CameraData));
	Game::GetInstance()->GetRenderSystem()->context->Unmap(constBuffer[0], 0);

	///

	ID3D11ShaderResourceView* resources[] = {
		Game::GetInstance()->GetRenderSystem()->gBuffer->diffuseSRV,
		Game::GetInstance()->GetRenderSystem()->gBuffer->normalSRV,
		Game::GetInstance()->GetRenderSystem()->gBuffer->worldPositionSRV
	};
	Game::GetInstance()->GetRenderSystem()->context->PSSetShaderResources(0, 3, resources);

	//POINT
	Game::GetInstance()->GetRenderSystem()->context->RSSetState(Game::GetInstance()->GetRenderSystem()->rastCullFront);
	Game::GetInstance()->GetRenderSystem()->context->IASetPrimitiveTopology(D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
	Game::GetInstance()->GetRenderSystem()->context->OMSetDepthStencilState(Game::GetInstance()->GetRenderSystem()->dsLightingGreater, 0);

	UINT strides[]{ 16 };
	UINT offsets[]{ 0 };
	Game::GetInstance()->GetRenderSystem()->context->IASetVertexBuffers(0, 1, poiVertexBuffer.GetAddressOf(), strides, offsets);
	Game::GetInstance()->GetRenderSystem()->context->IASetInputLayout(Game::GetInstance()->GetRenderSystem()->layoutLightingPoi); ///
	Game::GetInstance()->GetRenderSystem()->context->IASetIndexBuffer(poiIndexBuffer.Get(), DXGI_FORMAT_R32_UINT, 0);

	Game::GetInstance()->GetRenderSystem()->context->VSSetShader(Game::GetInstance()->GetRenderSystem()->vsLightingPoi, nullptr, 0);
	Game::GetInstance()->GetRenderSystem()->context->PSSetShader(Game::GetInstance()->GetRenderSystem()->psLightingPoi, nullptr, 0);
	Game::GetInstance()->GetRenderSystem()->context->GSSetShader(nullptr, nullptr, 0);

	Game::GetInstance()->GetRenderSystem()->context->VSSetConstantBuffers(0, 1, constBuffer);
	Game::GetInstance()->GetRenderSystem()->context->PSSetConstantBuffers(0, 1, constBuffer);

	Game::GetInstance()->GetRenderSystem()->context->DrawIndexed(poiIndices.size(), 0, 0);
}

void PointLightComponent::PoiAddMesh(float scaleRate, std::string objectFileName)
{
	Assimp::Importer importer;
	const aiScene* pScene = importer.ReadFile(objectFileName, aiProcess_Triangulate | aiProcess_ConvertToLeftHanded);

	if (!pScene) { return; }

	ProcessNode(pScene->mRootNode, pScene, scaleRate);
}
void PointLightComponent::ProcessNode(aiNode* node, const aiScene* scene, float scaleRate)
{
	for (UINT i = 0; i < node->mNumMeshes; i++)
	{
		aiMesh* mesh = scene->mMeshes[node->mMeshes[i]];
		ProcessMesh(mesh, scene, scaleRate);
	}

	for (UINT i = 0; i < node->mNumChildren; i++)
	{
		ProcessNode(node->mChildren[i], scene, scaleRate);
	}
}
void PointLightComponent::ProcessMesh(aiMesh* mesh, const aiScene* scene, float scaleRate)
{
	for (UINT i = 0; i < mesh->mNumVertices; i++) {
		poiPoints.push_back({ mesh->mVertices[i].x * scaleRate, mesh->mVertices[i].y * scaleRate, mesh->mVertices[i].z * scaleRate, 1.0f });	
	}

	for (UINT i = 0; i < mesh->mNumFaces; i++) {		
		aiFace face = mesh->mFaces[i];
		for (UINT j = 0; j < face.mNumIndices; j++)
		{
			poiIndices.push_back(face.mIndices[j]);
		}
	}
}