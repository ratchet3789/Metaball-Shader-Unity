using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class RaymarchCamera : SceneViewFilter
{
	[SerializeField]
	private Shader _shader;

	public Material _raymarchMaterial
	{
		get
		{
			if (!_raymarchMat && _shader)
			{
				_raymarchMat = new Material(_shader);
				_raymarchMat.hideFlags = HideFlags.HideAndDontSave;
			}
			return _raymarchMat;
		}
	}

	private Material _raymarchMat;

	public Camera _camera
	{
		get
		{
			if (!_cam)
			{
				_cam = FindObjectOfType<Camera>();
			}
			return _cam;
		}
	}

	private Camera _cam;
	public float _maxDistance;
	public Transform SunLight;
	public float sphereScale;
	public float smoothUnionScale;
	public Vector4 sphere1, sphere2, sphere3, sphere4;

	private void OnValidate()
	{
		if (_maxDistance == 0)
			_maxDistance = 10.0f;
		if (!SunLight)
			SunLight = FindObjectOfType<Light>().transform;
	}

	private void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		if (!_raymarchMaterial)
		{
			Graphics.Blit(source, destination);
			return;
		}
		_raymarchMaterial.SetTexture("_MainTex", source);
		_raymarchMaterial.SetVector("_LightDir", SunLight ? SunLight.forward : Vector3.down);

		_raymarchMaterial.SetMatrix("_FrustrumCornersES", CamFrustum(_camera));
		_raymarchMaterial.SetMatrix("_CameraInvViewMatrix", _camera.cameraToWorldMatrix);
		_raymarchMaterial.SetVector("_CameraWS", _camera.transform.position);
		_raymarchMaterial.SetFloat("_MaxDistance", _maxDistance);
		_raymarchMaterial.SetFloat("_SphereScale", sphereScale);
		_raymarchMaterial.SetFloat("_SmoothUnion", smoothUnionScale);

		_raymarchMat.SetVector("_Sphere1Position", new Vector4(transform.position.x, transform.position.y, transform.position.z, 0) + sphere1);
		_raymarchMat.SetVector("_Sphere2Position", new Vector4(transform.position.x, transform.position.y, transform.position.z, 0) + sphere2);
		_raymarchMat.SetVector("_Sphere3Position", new Vector4(transform.position.x, transform.position.y, transform.position.z, 0) + sphere3);
		_raymarchMat.SetVector("_Sphere4Position", new Vector4(transform.position.x, transform.position.y, transform.position.z, 0) + sphere4);

		RenderTexture.active = destination;
		GL.PushMatrix();
		GL.LoadOrtho();
		_raymarchMaterial.SetPass(0);
		GL.Begin(GL.QUADS);

		//Bottom Left
		GL.MultiTexCoord2(0, 0.0f, 0.0f);
		GL.Vertex3(0.0f, 0.0f, 3.0f);
		//Bottom Right
		GL.MultiTexCoord2(0, 1.0f, 0.0f);
		GL.Vertex3(1.0f, 0.0f, 2.0f);
		//Top Right
		GL.MultiTexCoord2(0, 1.0f, 1.0f);
		GL.Vertex3(1.0f, 1.0f, 1.0f);
		//TL
		GL.MultiTexCoord2(0, 0.0f, 1.0f);
		GL.Vertex3(0.0f, 1.0f, 0.0f);

		GL.End();
		GL.PopMatrix();
	}

	private Matrix4x4 CamFrustum(Camera cam)
	{
		Matrix4x4 Frustum = Matrix4x4.identity;
		float fov = Mathf.Tan((cam.fieldOfView * 0.5f) * Mathf.Deg2Rad);

		Vector3 goUp = Vector3.up * fov;
		Vector3 goRight = Vector3.right * fov * cam.aspect;

		Vector3 topLeft = (-Vector3.forward - goRight + goUp);
		Vector3 topRight = (-Vector3.forward + goRight + goUp);
		Vector3 bottomRight = (-Vector3.forward + goRight - goUp);
		Vector3 bottomLeft = (-Vector3.forward - goRight - goUp);

		Frustum.SetRow(0, topLeft);
		Frustum.SetRow(1, topRight);
		Frustum.SetRow(2, bottomRight);
		Frustum.SetRow(3, bottomLeft);

		return Frustum;
	}
}
