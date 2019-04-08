using UnityEngine;

public class MoveCamera : MonoBehaviour
{
    public float speed = 1f;
    public float smoothTime = 0.3F;

    void Move(float x, float z)
    {
        Vector3 pos = Camera.main.transform.position;
        Vector3 end = pos;
        end.x += x;
        end.z += z;
        Camera.main.transform.position = Vector3.Lerp(pos, end, smoothTime);
    }

    void Move(Vector3 dir)
    {
        Move(dir.x, dir.z);
    }

    void FixedUpdate()
    {
        if (Input.GetKey(KeyCode.A) || Input.GetKey(KeyCode.LeftArrow))
            Move(-transform.right * speed);

        if (Input.GetKey(KeyCode.D) || Input.GetKey(KeyCode.RightArrow))
            Move(transform.right * speed);

        if (Input.GetKey(KeyCode.W) || Input.GetKey(KeyCode.UpArrow))
            Move(transform.forward * speed);

        if (Input.GetKey(KeyCode.S) || Input.GetKey(KeyCode.DownArrow))
            Move(-transform.forward * speed);
    }
}
