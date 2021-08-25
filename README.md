# Worms Armageddon in a Docker container

There are two use cases. Firstly, run WA headlessly. Secondly, portable WA installation. \
Plus all the other uses cases you can think of.

## Headless

Replay processing first and foremost. Like for [WAaaS](https://waaas.zemke.io).

## Portable WA installation

Forwarding your display you can play Worms Armageddon from inside the Docker container
on your host system. I have already tried this. It runs well on Ubuntu as well as Mac.

This was merely a proof of concept, though. A todo is to make this easily reproducible
without having to have the technical knowhow.

I envision that this could be a much easier thing to set up and get running than using Wine.

## Dockerfiles

I had previously created a WA in a Docker container that was just the bare image, though.
I did not have a reproducible Dockerfile for this. If you want to see it, it's in `LEGACY.md`. \
What you can see in this repo is much better. This is heavily inspired by what CyberShadow did.

`Dockerfile` - This is the Dockerfile just for a headless Worms Armageddon installation
and convenience scripts for WA CLI options. You need to provide the `wa.iso` and
`wa_3_8_gog_update.exe` yourself. The update doesn't necessarily need to be from GOG,
but it allows for running WA without a CD.<sup>1</sup>

`Dockerfile.focal` - It's the same except it runs Ubuntu 20.04 and therefore doesn't need the
additional `cybermax-dexter/sdl2-backport` PPA. I just noticed it creates a lot more warnings
when running WA, so I decided not to use it as the standard.

There's also a Lambda extension which is basically this image plus
AWS Lambda Runtime Interface Client. \
This is utilized by WAaaS. Go there for detailed information how this is put into action.

<sup>1</sup> On the other hand, if you have the ISO, you have the CD, you'd just need
an additional layer to mount the CD when running WA. Maybe that's going to be done in
the future as it would be easier to apply newer updates which are in contrast to GOG
publicly available. I assume I'm going to migrate to this in the future.

## Usage

```console
docker run --rm -i wa wa-getlog < game.WAgame > game.log
```

Again, head over to WAaaS to see how it's also possible to extract the map for instance.

---

> I will not provide the ready-made image because you're supposed to have acquired a 
legal copy of this game. That's also why you have to provide the ISO file yourself.

