#pragma once

#include "includes.h"

using namespace DirectX::SimpleMath;

class DisplayWin32;
class RenderComponent;
class RenderShadowsComponent;

class RenderSystem
{
public:

	RenderSystem();

	void PrepareFrame();
	void Draw();
	void EndFrame();

	void InitializeShader(std::string shaderFileName);

	std::shared_ptr<D3D11_VIEWPORT> viewport;
	Microsoft::WRL::ComPtr<ID3D11Device> device;
	Microsoft::WRL::ComPtr<ID3D11DeviceContext> context;
	Microsoft::WRL::ComPtr<IDXGISwapChain> swapChain;
	Microsoft::WRL::ComPtr<ID3D11Texture2D> backBuffer;
	Microsoft::WRL::ComPtr<ID3D11RenderTargetView> renderView;
	Microsoft::WRL::ComPtr<ID3D11Texture2D> depthBuffer;
	Microsoft::WRL::ComPtr<ID3D11DepthStencilView> depthView;

	Microsoft::WRL::ComPtr<ID3D11InputLayout>     inputLayout;
	Microsoft::WRL::ComPtr<ID3D11VertexShader>    vertexShader;
	Microsoft::WRL::ComPtr<ID3D11PixelShader>     pixelShader;
	Microsoft::WRL::ComPtr<ID3D11RasterizerState> rastState;
	Microsoft::WRL::ComPtr<ID3D11SamplerState>    samplerState;

	std::vector<RenderComponent*> renderComponents;
};