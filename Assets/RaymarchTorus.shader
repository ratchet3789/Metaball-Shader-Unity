// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/RaymarchTorus"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" { }
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always
		
		Pass
		{
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			sampler2D _MainTex;
			float4x4 _FrustrumCornersES;
			uniform float4 _TexelSize;
			uniform float4x4 _CameraInvViewMatrix;
			uniform float3 _CameraWS;
			float _Scale;
			float _Size;
			float4 _LightDir;
			uniform sampler2D _CameraDepthTexture;
			float _SphereScale;
			float _SmoothUnion;
			float4 _Sphere1Position;
			float4 _Sphere2Position;
			float4 _Sphere3Position;
			float4 _Sphere4Position;
			
			struct appdata
			{
				float4 vertex: POSITION;
				float2 uv: TEXCOORD0;
			};
			
			struct v2f
			{
				float2 uv: TEXCOORD0;
				float4 vertex: SV_POSITION;
				float3 ray: TEXCOORD1;
			};
			
			float sdSphere(float3 p, float s)
			{
				return length(p) - s;
			}
			
			float sdTorus(float3 p, float2 t)
			{
				float2 q = float2(length(p.xz) - t.x, p.y);
				return length(q) - t.y;
			}
			
			float opSmoothUnion(float d1, float d2, float k)
			{
				float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
				return lerp(d2, d1, h) - k * h * (1.0 - h);
			}
			
			float map(float3 p)
			{
				float smoothFirstPass = opSmoothUnion
				(
					sdSphere(p + _Sphere1Position.xyz, _SphereScale),
					sdSphere(p + _Sphere2Position.xyz, _SphereScale),
					_SmoothUnion
				);
				
				float smoothSecondPass = opSmoothUnion
				(
					smoothFirstPass,
					sdSphere(p + _Sphere3Position.xyz, _SphereScale),
					_SmoothUnion
				);
				
				float smoothThirdPass = opSmoothUnion
				(
					smoothSecondPass,
					sdSphere(p + _Sphere4Position.xyz, _SphereScale),
					_SmoothUnion
				);
				
				return smoothThirdPass;
			}
			
			float3 calcNormal(in float3 pos)
			{
				const float2 eps = float2(0.001, 0.0);
				
				float3 tor = float3(map(pos + eps.xyy).x - map(pos - eps.xyy).x, map(pos + eps.yxy).x - map(pos - eps.yxy).x, map(pos + eps.yyx).x - map(pos - eps.yyx).x);
				return normalize(tor);
			}
			
			fixed4 raymarch(float3 rayOrigin, float3 rayDirection, float s)
			{
				fixed4 col = fixed4(0, 0, 0, 0);
				
				const int timeStep = 100;
				float travelled = 0;
				for (int i = 0; i < timeStep; i ++)
				{
					float3 position = rayOrigin + rayDirection * travelled;
					float d = map(position);
					
					if (travelled >= s)
					{
						col = fixed4(0, 0, 0, 0);
						break;
					}
					
					if(d < 0.001)
					{
						float3 n = calcNormal(position);
						col = fixed4(dot(-_LightDir.xyz, n).rrr, 1);
						break;
					}
					
					travelled += d;
				}
				return col;
			}
			
			v2f vert(appdata v)
			{
				v2f o;
				
				half index = v.vertex.z;
				v.vertex.z = 0.1;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv.xy;
				
				#if UNITY_UV_STARTS_AT_TOP
					if(_TexelSize.y < 0)
						o.uv.y = 1 - o.uv.y;
				#endif
				
				o.ray = _FrustrumCornersES[(int)index].xyz;
				//Normalize on the Z axis - viewspace position
				o.ray /= abs(o.ray.z);
				
				o.ray = mul(_CameraInvViewMatrix, o.ray);
				
				return o;
			}
			
			fixed4 frag(v2f i): SV_Target
			{
				float3 rayDir = normalize(i.ray.xyz);
				float3 rayOrigin = _CameraWS;
				
				float2 duv = i.uv;
				if (_TexelSize.y < 0)
					duv.y = 1 - duv.y;
				
				float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, duv).r);
				depth *= length(i.ray.xyz);
				
				fixed3 col = tex2D(_MainTex, i.uv);
				fixed4 add = raymarch(rayOrigin, rayDir, depth);
				
				return fixed4(col * (1.0 - add.w) + add.xyz * add.w, 1.0);
			}
			ENDCG
			
		}
	}
}
