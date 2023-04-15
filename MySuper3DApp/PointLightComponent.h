#pragma once

#include "TransformComponent.h"
#include "Component.h"

#include <assimp/Importer.hpp>
#include <assimp/scene.h>
#include <assimp/postprocess.h>

using namespace DirectX;

class PointLightComponent : public Component
{
public:

	PointLightComponent(float constant, float linear, float quadratic);
	PointLightComponent() = delete;

	Vector4 lightColor = { Vector3(1.0f, 1.0f, 1.0f) };

	float constant  = 1.0f;
	float linear    = 0.09f;
	float quadratic = 0.032f;
};
